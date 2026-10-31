import wave, struct, math, random
from pathlib import Path
random.seed(317)
root=Path(__file__).resolve().parents[1] / 'assets' / 'audio'
rate=22050
for name,duration in [('wind',16),('dread',4.5),('step',.24),('click',.1),('door',1.9),('pickup',.7),('power',2.2)]:
 data=[]; low=0
 for i in range(int(rate*duration)):
  t=i/rate; n=random.uniform(-1,1); low=low*.975+n*.025
  if name=='wind':
   env=math.sin(math.pi*t/duration)**.3
   v=(low*.5+math.sin(t*math.tau*47)*.025+math.sin(t*math.tau*71.0)*.012)*env
  elif name=='dread':
   env=min(1,t*2)*max(0,1-t/duration)
   v=(math.sin(math.tau*(46*t-2*t*t))*.25+math.sin(math.tau*68*t)*.1+low*.8)*env
   for hit in [0.2,1.3,2.8]:
    if 0<t-hit<.3:v+=math.sin((t-hit)*math.tau*70)*math.exp(-(t-hit)*22)*.5
  elif name=='step':v=(low*3+math.sin(t*math.tau*90)*.14)*math.exp(-t*27)*min(1,t*150)
  elif name=='click':v=(n*.3+math.sin(t*math.tau*600)*.2)*math.exp(-t*65)
  elif name=='door':v=(low*2+math.sin(math.tau*(70*t+40*t*t))*.08)*math.sin(math.pi*t/duration)+n*.2*math.exp(-t*25)
  elif name=='pickup':v=(math.sin(t*math.tau*660)+math.sin(t*math.tau*990)*.4)*.16*math.exp(-t*5)*min(1,t*40)
  else:v=(math.sin(t*math.tau*55)*.12+low*.8+math.sin(t*math.tau*110)*.05)*min(1,t*4)*min(1,(duration-t)*3)
  data.append(struct.pack('<h',int(max(-1,min(1,v))*26000)))
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(b''.join(data))
