#!/usr/bin/env bash
#
# Weekly recursive ZFS snapshot for entire Gandalf pool
# Keeps 4 top-level recursive snapshots, rotated
# Intended for use in cron (e.g., every Monday)

#—————— Config ——————
PATH=/usr/bin:/usr/sbin:/bin:/sbin
POOL="Gandalf"
LOGFILE="/mnt/grimoire/tmp/zfs-weekly-snap.log"
PREFIX="weekly"
MAX_SNAPS=4
#———————————————————————

DATESTAMP=$(/bin/date +%Y-%m-%d)
SNAPNAME="${PREFIX}-${DATESTAMP}"
FULL="${POOL}@${SNAPNAME}"

# Start logging
exec >> "$LOGFILE" 2>&1
echo "[$(/bin/date '+%F %T')] Creating recursive snapshot: $FULL"

/sbin/zfs snapshot -r "$FULL"

echo "[$(/bin/date '+%F %T')] Snapshot created. Now pruning old snapshots..."

# Find top-level snapshots matching the naming pattern
SNAPSHOTS=$(/sbin/zfs list -t snapshot -o name -s creation \
  | /bin/grep "^${POOL}@${PREFIX}-" \
  | /usr/bin/tail -n +$((MAX_SNAPS + 1)))

for snap in $SNAPSHOTS; do
  echo "[$(/bin/date '+%F %T')] Destroying recursive snapshot: $snap"
  /sbin/zfs destroy -r "$snap"
done

echo "[$(/bin/date '+%F %T')] Weekly snapshot complete."
