# Quick Start Guide 🚀

Get the EV Smart Screen running in 5 minutes!

---

## ⚡ Super Quick Start

### Step 1: Start Backend (Terminal 1)
```bash
cd backend
python main.py
```

**Expected Output:**
```
WebSocket server started on ws://localhost:8765
Telemetry simulator started (1 update/second)
✓ Backend ready!
```

### Step 2: Run Flutter App (Terminal 2)
```bash
flutter run -d windows
```

**Expected:** App launches and connects automatically!

---

## 🎯 What to Explore

### 1. Home Screen (Default)
- Watch speed, range, battery update every second
- See media player with live track info
- Check connection icons (top-left)
- Click notification bell (top-right)

### 2. Map Screen
- Click "Apps" (bottom navigation)
- Click "Maps" icon
- Watch vehicle marker move in real-time
- See route path build up
- Toggle follow mode (top-right)

### 3. Diagnostics Screen
- Click "Apps" → "Diagnostics"
- Watch 4 gauges update
- Scroll down to see charts (wait 2-3 min for trends)
- View eco-driving score
- Check analytics metrics

### 4. Settings Screen
- Click "Apps" → "Settings"
- Change any setting (e.g., charge limit)
- Watch backend logs confirm command
- Restart app - settings persist!

---

## 🧪 Quick Tests

### Test 1: Real-time Data (30 seconds)
1. Watch home screen metrics change
2. All values should update every second
3. ✅ Pass if numbers change smoothly

### Test 2: Map Tracking (1 minute)
1. Go to Maps
2. Watch vehicle marker move
3. See route line appear
4. ✅ Pass if marker moves and route draws

### Test 3: Notifications (2 minutes)
1. Wait for battery to drop below 20%
2. Toast notification should appear
3. Click bell icon to see history
4. ✅ Pass if notification shows

### Test 4: Charts (3 minutes)
1. Go to Diagnostics
2. Wait 2-3 minutes
3. Charts should show trends
4. ✅ Pass if charts have data

### Test 5: Analytics (1 minute)
1. Scroll to Analytics section
2. See eco score (0-100)
3. Check energy consumption
4. ✅ Pass if metrics display

---

## 🐛 Troubleshooting

### Problem: App won't connect
**Solution:**
```bash
# Check backend is running
# Should see "WebSocket server started..."

# Restart backend
Ctrl+C
python main.py

# Restart Flutter app
r (in Flutter terminal)
```

### Problem: No data showing
**Solution:**
```bash
# Check backend logs
# Should see "Telemetry update sent" every second

# If not, restart backend
```

### Problem: Charts not updating
**Solution:**
```bash
# Wait 2-3 minutes for data to accumulate
# Charts need at least 30 data points to show trends
```

### Problem: Map not loading
**Solution:**
```bash
# Check internet connection (map tiles need internet)
# Wait 5-10 seconds for tiles to load
# Try zooming in/out
```

---

## 📊 What You Should See

### After 30 seconds:
- ✅ All metrics updating
- ✅ Connection status green
- ✅ Media player showing track

### After 2 minutes:
- ✅ Charts starting to show data
- ✅ Route path visible on map
- ✅ Analytics calculating

### After 5 minutes:
- ✅ Charts showing full trends
- ✅ Long route path on map
- ✅ Accurate analytics
- ✅ Possible notifications

---

## 🎮 Cool Things to Try

### 1. Test Disconnection
```bash
# Stop backend (Ctrl+C)
# Watch connection status turn red
# Restart backend
# Watch auto-reconnect (green)
```

### 2. Change Settings
```bash
# Go to Settings
# Move charge limit slider
# Check backend logs for command
# Restart app - setting persists!
```

### 3. Reset Trip
```bash
# Go to Diagnostics → Analytics
# Click "Reset Trip"
# Watch all trip stats reset
# Start driving again
```

### 4. Clear Route
```bash
# Go to Maps
# Click clear button (top-right)
# Route path disappears
# Starts fresh
```

---

## 📈 Performance Check

### Good Performance:
- Smooth 60 FPS (no lag)
- <250MB memory usage
- <5% CPU usage
- Instant response to taps

### If Slow:
```bash
# Close other apps
# Restart Flutter app
# Check Task Manager for resource usage
```

---

## 🎯 Success Checklist

After 5 minutes, you should have:
- [ ] ✅ Backend running
- [ ] ✅ Flutter app connected
- [ ] ✅ Home screen updating
- [ ] ✅ Map showing vehicle
- [ ] ✅ Charts displaying data
- [ ] ✅ Analytics calculating
- [ ] ✅ Settings working
- [ ] ✅ Notifications appearing

**If all checked: Congratulations! 🎉**

---

## 📚 Next Steps

1. **Read Full Documentation:**
   - `README.md` - Complete overview
   - `documentation/PHASE_3_COMPLETE.md` - All features
   - `documentation/PHASE_2_TESTING_GUIDE.md` - Detailed testing

2. **Explore Features:**
   - Try all settings
   - Watch analytics change
   - Test notifications
   - Explore map controls

3. **Customize:**
   - Modify backend data
   - Adjust thresholds
   - Change colors
   - Add features

---

## 🆘 Need Help?

### Check Logs:
```bash
# Backend logs (Terminal 1)
# Shows all commands and data

# Flutter logs (Terminal 2)
# Shows connection status and errors
```

### Common Issues:
1. **Port 8765 in use:** Close other apps using it
2. **No internet:** Map tiles won't load
3. **Slow performance:** Close other apps
4. **Connection fails:** Check firewall settings

---

## 🎉 You're Ready!

**Enjoy exploring the EV Smart Screen!**

**Made with ❤️ and Flutter**

---

**Developer:** Guneet Chawla  
**Email:** guneet.chawla.22cse@bmu.edu.in  
**Institution:** BML Munjal University
