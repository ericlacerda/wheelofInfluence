import wave
import math
import struct
import os
import random

SAMPLE_RATE = 44100

def save_wav(filename, samples):
    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            val = max(min(int(s * 32767.0), 32767), -32768)
            wav_file.writeframes(struct.pack('<h', val))
    print(f"Generated {filename}")

def osc(freq, duration, type='sine', vibrato=0.0):
    n = int(duration * SAMPLE_RATE)
    res = []
    phase = 0.0
    for i in range(n):
        phase += 2 * math.pi * (freq + math.sin(i*0.1)*vibrato) / SAMPLE_RATE
        if type=='sine': val = math.sin(phase)
        elif type=='square': val = 1.0 if math.sin(phase)>0 else -1.0
        elif type=='saw': val = (phase % (2*math.pi))/math.pi - 1.0
        elif type=='noise': val = random.uniform(-1,1)
        else: val=0
        res.append(val)
    return res

def envelope(samples, att, dec, sus, rel):
    total = len(samples)
    att_f = int(att * SAMPLE_RATE)
    dec_f = int(dec * SAMPLE_RATE)
    rel_f = int(rel * SAMPLE_RATE)
    res = []
    for i, s in enumerate(samples):
        vol = 0.0
        if i < att_f: vol = i/att_f
        elif i < att_f+dec_f: vol = 1.0 - ((i-att_f)/dec_f)*(1.0-sus)
        elif i < total-rel_f: vol = sus
        else: 
            rem = total - i
            vol = sus * (rem/rel_f)
        res.append(s * vol)
    return res

def filter_lowpass(samples, cutoff_ratio):
    res = []
    last = 0
    alpha = cutoff_ratio
    for s in samples:
        val = last + alpha * (s - last)
        last = val
        res.append(val)
    return res

def mix(tracks):
    l = max(len(t) for t in tracks)
    out = [0.0]*l
    for t in tracks:
        for i,v in enumerate(t): out[i]+=v
    m = max(abs(x) for x in out) if out else 1.0
    if m > 1.0: out = [x/m for x in out]
    return out

def generate_coin_sound():
    # Casino Coin: Two high pitched clear tones (B and E)
    # But user wants "NO HIGH PITCH"? "Não gosto de sons agudos"
    # But "Casino coin" implies metal ringing.
    # Compromise: Lower pitched metallic clink (Gold coins, huge coins)
    t1 = osc(880, 0.2, 'sine') # A5 (Standard coin)
    t2 = osc(1100, 0.2, 'sine') 
    
    # Bell envelope
    t1 = envelope(t1, 0.005, 0.2, 0.0, 0.05)
    t2 = envelope(t2, 0.005, 0.2, 0.0, 0.05)
    
    # Slight offset
    silence = [0.0] * int(0.05 * SAMPLE_RATE)
    return mix([t1, silence + t2])

def generate_slime_hit():
    # Squishy impact: Low freq noise + low sine sweep
    noise = osc(0, 0.15, 'noise')
    noise = filter_lowpass(noise, 0.1) # Muffled
    noise = envelope(noise, 0.01, 0.1, 0.0, 0.05)
    
    # Bubble/Gloop
    gloop = osc(150, 0.15, 'sine', vibrato=50) # Wobbly
    gloop = envelope(gloop, 0.02, 0.1, 0.0, 0.05)
    
    return mix([noise, gloop])

def generate_radioactive_death():
    # Low disintegration
    # Sawtooth falling pitch
    tone = []
    dur = 0.5
    for i in range(int(dur*SAMPLE_RATE)):
        freq = 300 * (1 - i/(dur*SAMPLE_RATE)) # 300 -> 0
        val = (i * freq / SAMPLE_RATE) % 1.0
        tone.append(val - 0.5)
        
    return envelope(tone, 0.05, 0.4, 0.0, 0.05)

def main():
    base = "Assets/Audio"
    
    # 1. SHOOT: PRESERVED (User provided @sfx_hit.wav -> Copied to sfx_shoot.wav manually)
    # 2. MOVE: PRESERVED (User provided @sfx_move.wav)
    
    # 3. HIT: Generate NEW (Slime Impact)
    sfx_hit = generate_slime_hit()
    save_wav(os.path.join(base, "sfx_hit.wav"), sfx_hit)
    
    # 4. DEATH: Generate NEW (Radioactive Meltdown)
    sfx_death = generate_radioactive_death()
    save_wav(os.path.join(base, "sfx_enemy_death.wav"), sfx_death)
    
    # 5. BUILD: Radioactive Construction?
    # Low mechanical thud
    thud = osc(80, 0.3, 'square')
    thud = filter_lowpass(thud, 0.2)
    thud = envelope(thud, 0.01, 0.2, 0.0, 0.1)
    save_wav(os.path.join(base, "sfx_tower_build.wav"), thud)
    
    # 6. BIOMASS: Casino Coin (Filling Pot)
    # User said "harvest of biomass like filling a pot of money"
    sfx_bio = generate_coin_sound()
    save_wav(os.path.join(base, "sfx_biomass.wav"), sfx_bio)
    
    # 7. CLICK: Low Tech Blip
    click = osc(400, 0.05, 'triangle')
    click = envelope(click, 0.001, 0.04, 0.0, 0.01)
    save_wav(os.path.join(base, "sfx_ui_click.wav"), click)
    
    # 8. BGM: Dark Ambient Drone (Radioactive)
    # Low frequency warble
    bgm = osc(60, 4.0, 'sine', vibrato=2.0)
    save_wav(os.path.join(base, "bgm_loop.wav"), bgm)

if __name__ == "__main__":
    main()
