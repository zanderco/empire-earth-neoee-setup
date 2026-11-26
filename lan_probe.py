#!/usr/bin/env python3
"""Two-Mac LAN probe for the Empire Earth family setup (Python 3 stdlib only).

Separates "the network/macOS blocks it" from "the game/Wine does it wrong".
It never touches the game, Wine prefix, firewall or system settings.

  info     What this Mac would advertise: hostname resolution order (what Wine's
           getaddrinfo sees), interfaces, default route, Local Network rules.
  listen   Receive UDP broadcasts/unicasts and accept TCP, like a game host.
  send     Broadcast + unicast UDP and a TCP connect to a peer, like a joiner.

Typical two-Mac run (game NOT running, so the game ports are free, or use the
default offset ports which never collide with the game):
  Mac A:  python3 scripts/lan_probe.py listen --seconds 120
  Mac B:  python3 scripts/lan_probe.py send --to <Mac A IPv4>
Then swap roles. Results print as JSON; --output also saves them.

Launch context matters on macOS 15+: Terminal-launched tools are exempt from
Local Network privacy, apps launched from Finder are not (Apple TN3179). A pass
here proves the network path, not that a Finder-launched wrapper is allowed.
"""
import argparse, datetime, json, os, platform, re, socket, subprocess, sys, time

GAME_UDP_DISCOVERY = 8585   # observed NeoEE LAN discovery bind (Sep 8 trace)
GAME_LOBBY = 33336          # observed NeoEE UDP bind + TCP listen (Sep 8 trace)
DEFAULT_UDP = 28585         # probe defaults: offset so a running game never collides
DEFAULT_TCP = 43336
MAGIC = b'EEFAMILY-PROBE-1 '


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
    except Exception as e:  # noqa: BLE001 - diagnostic tool, report anything
        return f'ERROR {e}'


def interfaces():
    """IPv4 interfaces from ifconfig: name, address, broadcast."""
    out, cur = [], None
    for line in run(['ifconfig']).splitlines():
        m = re.match(r'^(\S+): flags=\w+<([^>]*)>', line)
        if m:
            cur = {'name': m.group(1), 'flags': m.group(2).split(',')}
            continue
        m = re.match(r'\s+inet (\S+) netmask (\S+)(?: broadcast (\S+))?', line)
        if m and cur:
            out.append({'name': cur['name'], 'address': m.group(1),
                        'broadcast': m.group(3), 'up': 'UP' in cur['flags'],
                        'broadcast_capable': 'BROADCAST' in cur['flags']})
    return out


def default_route():
    out = run(['route', '-n', 'get', 'default'])
    return {k: v for k, v in re.findall(r'^\s*(gateway|interface):\s*(\S+)', out, re.M)}


def resolve_order(name):
    try:
        return [a[4][0] for a in socket.getaddrinfo(name, None, socket.AF_UNSPEC)]
    except OSError as e:
        return f'ERROR {e}'


def local_network_rules():
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import local_network_state
        rules = local_network_state.load()
    except Exception as e:  # noqa: BLE001
        return f'unavailable: {e}'
    keep = []
    for r in rules:
        ident = str(r.get('SigningIdentifier', ''))
        if re.search(r'empire|wineskin|portingkit|terminal|python', ident, re.I):
            decided = r.get('MulticastPreferenceSet')
            keep.append({'id': ident, 'state': 'undecided' if not decided
                         else 'denied' if r.get('DenyMulticast') else 'allowed'})
    return keep


def info(_args):
    host = socket.gethostname()
    order = resolve_order(host)
    v4 = [a for a in order if isinstance(order, list) and ':' not in a] if isinstance(order, list) else []
    lan = [i for i in interfaces() if i['broadcast_capable'] and not i['address'].startswith('127.')]
    return {
        'mode': 'info',
        'macos': platform.mac_ver()[0], 'machine': platform.machine(),
        'hostname': host,
        'hostname_resolution_order': order,
        'first_ipv4_is_loopback': bool(v4) and v4[0].startswith('127.'),
        'default_route': default_route(),
        'lan_candidates': lan,
        'all_ipv4_interfaces': interfaces(),
        'local_network_rules': local_network_rules(),
        'firewall': run(['/usr/libexec/ApplicationFirewall/socketfilterfw', '--getglobalstate']).strip(),
        'notes': ['Wine gethostbyname(own name) uses adapter/route tables, not DNS;',
                  'Wine getaddrinfo(own name) uses this macOS resolver order.'],
    }


def listen(args):
    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    udp.bind(('0.0.0.0', args.udp_port))
    udp.settimeout(0.2)
    tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tcp.bind(('0.0.0.0', args.tcp_port))
    tcp.listen(16)
    tcp.settimeout(0.2)
    print(f'listening UDP {args.udp_port} and TCP {args.tcp_port} for {args.seconds}s '
          f'on {socket.gethostname()}; start "send" on the other Mac now', file=sys.stderr)
    got, end = [], time.monotonic() + args.seconds
    while time.monotonic() < end:
        try:
            data, src = udp.recvfrom(2048)
            if data.startswith(MAGIC):
                got.append({'proto': 'udp', 'from': src[0], 'payload': data[len(MAGIC):].decode(errors='replace')})
                print(f'UDP from {src[0]}: {data[len(MAGIC):].decode(errors="replace")}', file=sys.stderr)
                reply = MAGIC + f'reply from {socket.gethostname()}'.encode()
                try:
                    udp.sendto(reply, src)
                except OSError as e:
                    got.append({'proto': 'udp-reply', 'to': src[0], 'error': f'{e.errno} {e.strerror}'})
        except socket.timeout:
            pass
        try:
            conn, src = tcp.accept()
            with conn:
                conn.settimeout(2)
                data = conn.recv(2048)
                conn.sendall(MAGIC + b'tcp ok')
            got.append({'proto': 'tcp', 'from': src[0], 'payload': data[len(MAGIC):].decode(errors='replace')})
            print(f'TCP from {src[0]}', file=sys.stderr)
        except socket.timeout:
            pass
    return {'mode': 'listen', 'udp_port': args.udp_port, 'tcp_port': args.tcp_port,
            'seconds': args.seconds, 'received': got,
            'verdict': 'received traffic' if got else 'NOTHING RECEIVED'}


def attempt(fn):
    try:
        return {'ok': True, **(fn() or {})}
    except OSError as e:
        return {'ok': False, 'errno': e.errno, 'error': e.strerror or str(e)}


def send(args):
    me = socket.gethostname()
    targets = ['255.255.255.255'] + sorted({i['broadcast'] for i in interfaces()
                                            if i['broadcast'] and i['up']})
    if args.to:
        targets.append(args.to)
    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    udp.bind(('0.0.0.0', 0))
    udp.settimeout(0.3)
    results = []
    for rnd in range(args.rounds):
        for t in targets:
            payload = MAGIC + f'{me} round {rnd} to {t}'.encode()
            results.append({'udp_to': t, 'round': rnd,
                            **attempt(lambda: {'bytes': udp.sendto(payload, (t, args.udp_port))})})
        time.sleep(0.5)
    replies = []
    end = time.monotonic() + 2
    while time.monotonic() < end:
        try:
            data, src = udp.recvfrom(2048)
            if data.startswith(MAGIC):
                replies.append({'from': src[0], 'payload': data[len(MAGIC):].decode(errors='replace')})
        except socket.timeout:
            pass
        except OSError as e:
            replies.append({'error': f'{e.errno} {e.strerror}'})
            break
    tcp = None
    if args.to:
        def connect():
            with socket.create_connection((args.to, args.tcp_port), timeout=5) as c:
                c.sendall(MAGIC + f'hello from {me}'.encode())
                return {'reply': c.recv(64)[len(MAGIC):].decode(errors='replace')}
        tcp = {'to': args.to, 'port': args.tcp_port, **attempt(connect)}
    failures = [r for r in results if not r['ok']]
    return {'mode': 'send', 'from': me, 'udp_port': args.udp_port,
            'udp_sends': results, 'udp_send_failures': len(failures),
            'udp_replies': replies, 'tcp_connect': tcp,
            'hints': hints(failures, replies, tcp)}


def hints(failures, replies, tcp):
    h = []
    errs = {f.get('errno') for f in failures}
    if 65 in errs or 51 in errs:
        h.append('EHOSTUNREACH/ENETUNREACH on send: Local Network privacy denied for the '
                 'launching app, no network, or wrong interface. Check System Settings > '
                 'Privacy & Security > Local Network.')
    if not replies:
        h.append('No UDP replies: listener not running, client isolation on the Wi-Fi, '
                 'different subnets, or the listener side lacks Local Network access.')
    if tcp and not tcp['ok']:
        h.append('TCP connect failed: wrong IP, listener not running, or network isolation.')
    return h


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('info')
    lp = sub.add_parser('listen'); lp.add_argument('--seconds', type=int, default=120)
    sp = sub.add_parser('send'); sp.add_argument('--to'); sp.add_argument('--rounds', type=int, default=3)
    for p in (lp, sp):
        p.add_argument('--udp-port', type=int, default=DEFAULT_UDP)
        p.add_argument('--tcp-port', type=int, default=DEFAULT_TCP)
        p.add_argument('--game-ports', action='store_true',
                       help=f'use real game ports UDP {GAME_UDP_DISCOVERY} / TCP {GAME_LOBBY} (game must be closed)')
    ap.add_argument('--output', help='also save JSON here')
    args = ap.parse_args()
    if getattr(args, 'game_ports', False):
        args.udp_port, args.tcp_port = GAME_UDP_DISCOVERY, GAME_LOBBY
    result = {'info': info, 'listen': listen, 'send': send}[args.cmd](args)
    result['time_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    text = json.dumps(result, indent=2)
    print(text)
    if args.output:
        with open(args.output, 'w') as f:
            f.write(text + '\n')


if __name__ == '__main__':
    main()
