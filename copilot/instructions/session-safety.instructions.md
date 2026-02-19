---
description: "CRITICAL: Hardware system session safety - prevent device contention and context loss"
applyTo: "**"
---

# Session Safety Guidelines

This guideline prevents session hangs and context loss on hardware development systems, particularly when working with NPU/GPU devices.

## Critical Problem: Session Accumulation

**Root Cause**: Multiple sessions accessing hardware devices simultaneously causes:
- Device contention and driver conflicts
- Resource leakage from zombie processes
- Progressive system instability
- Complete context loss requiring system restart

## Before Every Session

### 1. Session Cleanup (MANDATORY)

```bash
pkill -f claude || true
sleep 2
pkill -9 -f claude || true
ps aux | grep claude | grep -v grep
```

### 2. Device Resource Validation

```bash
lsof /dev/dri/card0 2>/dev/null && echo "WARNING: Device in use" || echo "Device available"
free -h | grep Mem
uptime
timeout 5s docker version >/dev/null || echo "Docker daemon issue"
```

### 3. Environment Reset

```bash
docker container prune -f
docker system prune -f
rm -rf /dev/shm/rknn* 2>/dev/null || true
rm -rf /dev/shm/npu* 2>/dev/null || true
find /tmp -name "*claude*" -mtime +1 -delete 2>/dev/null || true
```

## During Sessions

### Hardware Testing Safety

**NEVER** run hardware tests without these protections:

```bash
timeout 60s docker run --rm \
  --memory=512m \
  --cpus=1.0 \
  --device /dev/dri/card0 \
  test-container timeout 45s ./test-script.sh
```

### Progress Preservation

Save work frequently to prevent context loss:

```bash
git add . && git commit -m "WIP: checkpoint $(date)" || true
```

### Session Monitoring

Watch for warning signs:
- Multiple processes accessing `/dev/dri/card0`
- Tests taking longer than expected
- System responsiveness degrading
- Memory usage climbing without reason

## Emergency Recovery

### 1. Force Termination
```bash
pkill -KILL -f claude
pkill -KILL -f docker
```

### 2. Device Reset
```bash
lsof /dev/dri/card0 | awk 'NR>1 {print $2}' | xargs -r kill -9
sudo systemctl restart docker
```

### 3. System Cleanup
```bash
docker kill $(docker ps -q) 2>/dev/null || true
docker container prune -f
docker system prune -f
rm -rf /dev/shm/* 2>/dev/null || true
```

## Hardware-Specific Rules

### NPU/GPU Development Systems
- **One session only**: Never run multiple AI coding sessions
- **Device exclusivity**: Verify exclusive hardware access
- **Resource limits**: Always use memory/CPU limits in containers
- **Timeout everything**: No operation without explicit timeouts

### Recovery Time
- Allow 5-10 minutes between crashed sessions
- Verify complete cleanup before restarting
- Consider system reboot if multiple crashes occur
