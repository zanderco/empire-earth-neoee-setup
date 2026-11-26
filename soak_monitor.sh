#!/bin/bash
# Once a minute, record the Empire Earth game process: CPU, memory, uptime,
# thread count, open sockets, and system load. Gaps between timestamps mean the
# whole Mac stalled; a line with cpu near 0 or >300 for many minutes means the
# game itself hung or spun. Usage: soak_monitor.sh <output.log>
out="${1:?output log path}"
pat='^/.*drive_c/NeoEE/Empire Earth/Empire Earth\.exe'
while pid=$(pgrep -f "$pat" | head -1) && [ -n "$pid" ]; do
  s=$(ps -p "$pid" -o pcpu=,rss=,etime= | tr -s ' ')
  th=$(ps -M -p "$pid" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  so=$(lsof -nP -a -p "$pid" -i 2>/dev/null | tail -n +2 | awk '{print $8 $9}' | tr '\n' ',')
  echo "$(date -u +%FT%TZ) pid=$pid cpu_rss_up=$s threads=$th load=$(sysctl -n vm.loadavg) socks=$so" >> "$out"
  sleep 60
done
echo "$(date -u +%FT%TZ) game-not-running" >> "$out"
