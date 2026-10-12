#!/bin/zsh
# Site captures for wodrounds.iamjarl.com (#182), one language per run.
# See README.md in this folder. Needs a Debug build of WODrounds (iOS, tvOS, watchOS)
# in $DD/Build/Products, which carries the -site launch arguments.
#
#   appstore/site/capture.sh <en|da|es> <out-dir>
#
# Simulators: an iPhone 17 Pro, an Apple TV 4K and an Apple Watch Series 12 (46 mm).
# Override them with PHONE, TV and WATCH (UDIDs).
set -eu
L=$1; OUT=$2; mkdir -p $OUT
DD=${DD:?set DD to the derived data path of a Debug build}
PHONE=${PHONE:?iPhone 17 Pro UDID}; TV=${TV:?Apple TV 4K UDID}; WATCH=${WATCH:?Apple Watch 46 mm UDID}
case $L in en) LOC=en_US;; da) LOC=da_DK;; es) LOC=es_MX;; *) echo "en, da or es"; exit 1;; esac

# The locale has to be the simulator's own, not only a launch argument, or the status
# bar writes the time in the wrong language.
setlang() {
  xcrun simctl shutdown $1 2>/dev/null || true
  xcrun simctl boot $1; xcrun simctl bootstatus $1 -b >/dev/null
  xcrun simctl spawn $1 defaults write -g AppleLocale -string $LOC
  xcrun simctl spawn $1 defaults write -g AppleLanguages -array $L
  xcrun simctl shutdown $1; xcrun simctl boot $1; xcrun simctl bootstatus $1 -b >/dev/null
}

B=com.iamjarl.WODrounds
# A real Tabata, 20/10 x 8, and a plausible EMOM, 12 x 1:00.
TAB=(-intervalsWorkSeconds 20 -intervalsRestSeconds 10 -intervalsRounds 8)
EMOM=(-emomRounds 12 -emomRoundLengthSeconds 60)

# iPhone
setlang $PHONE
xcrun simctl ui $PHONE appearance dark
xcrun simctl status_bar $PHONE override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --operatorName "" --batteryState discharging --batteryLevel 100
xcrun simctl install $PHONE $DD/Build/Products/Debug-iphonesimulator/WODrounds.app
# -siteElapsed is taken at launch, and the shot comes ~2.5 s later; the numbers allow for it.
shot() { name=$1; shift; xcrun simctl terminate $PHONE $B 2>/dev/null || true
  xcrun simctl launch $PHONE $B -soundEnabled YES "$@" >/dev/null; sleep 2.5
  xcrun simctl io $PHONE screenshot $OUT/$name-$L.png >/dev/null; echo "$name-$L"; }
shot emom-setup -screen emom $EMOM
shot emom-running -screen emom $EMOM -siteElapsed 199.5          # round 4 of 12, ~0:38 left
shot intervals-running -screen intervals $TAB -siteElapsed 64.5  # round 3, work, ~0:14 left
shot intervals-rest -screen intervals $TAB -siteElapsed 80.5     # round 3, rest, ~0:07 left
shot fortime-done -screen fortime -forTimeCapSeconds 0 -siteElapsed 767 -siteFinished YES  # 12:47
shot countin -screen emom $EMOM -siteCountIn 9.5
# The hero loop: round 3 from ~0:16 of work, recorded for 26 s; README has the cut.
xcrun simctl terminate $PHONE $B 2>/dev/null || true
xcrun simctl launch $PHONE $B -soundEnabled YES -screen intervals $TAB -siteElapsed 64 >/dev/null
xcrun simctl io $PHONE recordVideo --codec=h264 --force $OUT/loop-$L-raw.mp4 >/dev/null 2>&1 &
sleep 26; kill -INT $!; sleep 3; echo "loop-$L"

# Apple TV
setlang $TV
xcrun simctl install $TV $DD/Build/Products/Debug-appletvsimulator/WODrounds.app
xcrun simctl launch $TV $B -soundEnabled YES -screen intervals $TAB -siteElapsed 64.5 >/dev/null; sleep 4
xcrun simctl io $TV screenshot $OUT/tv-intervals-$L.png >/dev/null; echo "tv-$L"
xcrun simctl shutdown $TV

# Apple Watch (standalone Intervals; the Watch keeps its own setup keys)
setlang $WATCH
xcrun simctl install $WATCH "$DD/Build/Products/Debug-watchsimulator/WODrounds Watch.app"
xcrun simctl launch $WATCH $B.watchkitapp -watchTimerMode intervals -watchIntervalsWork 20 \
  -watchIntervalsRest 10 -watchIntervalsRounds 8 -siteElapsed 64.5 >/dev/null; sleep 4
xcrun simctl io $WATCH screenshot $OUT/watch-intervals-$L.png >/dev/null; echo "watch-$L"
