"""Offline design prototype only. Statistical comparison, never a diagnosis/Ridge input."""
from datetime import datetime,timedelta
from statistics import median
import math

from generator import CONFIG

RULES=CONFIG["trend"]


def daily_readings(samples,now,zone):
    """Samples are (aware timestamp, bpm). No device IDs/source copies required."""
    today=now.astimezone(zone).date()
    start=today-timedelta(days=RULES["baseline_days"]+RULES["recent_days"])
    selected={}
    for stamp,bpm in samples:
        if stamp.tzinfo is None: raise ValueError("Aware timestamps required")
        day=stamp.astimezone(zone).date()
        if not math.isfinite(bpm) or bpm<=0 or not start<=day<today: continue
        # Compare instants, including the repeated local hour at a DST fall-back.
        candidate=(stamp.timestamp(),bpm)
        if day not in selected or candidate>selected[day]: selected[day]=candidate
    return {day:item[1] for day,item in selected.items()}


def compare(days,completed_day):
    def result(state,reason,direction=None,**detail):
        return dict(state=state,reason=reason,direction=direction,**detail)
    def valid(day):
        value=days.get(day)
        return value is not None and math.isfinite(value) and value>0
    recent=[completed_day-timedelta(days=i) for i in range(RULES["recent_days"]-1,-1,-1)]
    first=recent[0]-timedelta(days=RULES["baseline_days"])
    baseline=[first+timedelta(days=i) for i in range(RULES["baseline_days"])]
    if not valid(completed_day): return result("Not enough recent data","latest completed day unavailable")
    observed=[days[d] for d in baseline if valid(d)]
    if len(observed)<RULES["minimum_baseline_days"]:
        return result("Not enough recent data","baseline coverage")
    if any(sum(valid(d) for d in baseline[i:i+7])<RULES["minimum_per_week"] for i in range(0,28,7)):
        return result("Not enough recent data","baseline coverage too concentrated")
    if sum(valid(d) for d in recent)<RULES["minimum_recent_days"]:
        return result("Not enough recent data","recent coverage")
    center=median(observed);spread=RULES["mad_factor"]*median([abs(v-center) for v in observed])
    if spread<=0: return result("Not enough recent data","not enough baseline variation to estimate a range")
    limit=RULES["statistical_multiplier"]*spread
    flags={d:(1 if days[d]>center+limit else -1 if days[d]<center-limit else 0) for d in recent if valid(d)}
    details=dict(baseline_median=center,robust_scale=spread,lower=center-limit,upper=center+limit,
        baseline_days=len(observed),recent_days=len(flags))
    last_two=[completed_day-timedelta(days=i) for i in range(RULES["clear_consecutive_days"])]
    if all(flags.get(d)==0 for d in last_two) or all(v==0 for v in flags.values()):
        return result("Within recent usual range","recent statistical comparison only",**details)
    upper=sum(v==1 for v in flags.values());lower=sum(v==-1 for v in flags.values())
    direction="higher" if upper and not lower else "lower" if lower and not upper else "varied"
    persistent=max(upper,lower)>=RULES["persistent_days"] and min(upper,lower)==0
    return result("Persistently different from recent baseline" if persistent else "Noticeably different from recent baseline",
        "non-diagnostic personal comparison",direction,**details)


def assess(samples,now,zone):
    return compare(daily_readings(samples,now,zone),now.astimezone(zone).date()-timedelta(days=1))
