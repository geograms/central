import React from 'react';

export default function GeogramLogo() {
  return (
    <div className="min-h-screen bg-slate-950 p-8 font-sans">
      <h1 className="text-3xl font-bold text-white mb-2 tracking-tight">Geogram Logo</h1>
      <p className="text-slate-400 mb-4">Radio waves + Bluetooth • Classic satellite • Person broadcasting</p>
      <p className="text-slate-500 text-sm mb-12">H: ····  O: ———  P: ·——·  E: ·</p>
      
      <div className="grid gap-20">
        
        <section>
          <h2 className="text-cyan-400 text-sm font-mono uppercase tracking-widest mb-2">Current Design</h2>
          <p className="text-slate-500 text-sm mb-6">Radio on left, Bluetooth on right, classic satellite orbiting</p>
          <div className="flex flex-wrap gap-8 items-center">
            
            {/* Beach sketch style - PRIMARY */}
            <div className="bg-amber-50 rounded-2xl p-10 flex flex-col items-center gap-4 border-2 border-amber-200">
              <svg width="160" height="160" viewBox="0 0 100 100" fill="none" stroke="#78350f" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                
                {/* Morse code arc - right side only */}
                {/* H: 4 dots - spread along arc */}
                <circle cx="50" cy="8" r="2" fill="#78350f"/>
                <circle cx="56" cy="8.5" r="2" fill="#78350f"/>
                <circle cx="62" cy="10" r="2" fill="#78350f"/>
                <circle cx="68" cy="12" r="2" fill="#78350f"/>
                
                {/* GAP */}
                
                {/* O: 3 dashes - following the circle curve */}
                <line x1="78" y1="20" x2="82" y2="27"/>
                <line x1="86" y1="34" x2="89" y2="42"/>
                <line x1="91" y1="49" x2="91" y2="57"/>
                
                {/* GAP */}
                
                {/* P: dot dash dash dot - tighter spacing */}
                <circle cx="89" cy="68" r="2" fill="#78350f"/>
                <line x1="87" y1="73" x2="84" y2="78"/>
                <line x1="80" y1="82" x2="75" y2="85"/>
                <circle cx="68" cy="88" r="2" fill="#78350f"/>
                
                {/* GAP */}
                
                {/* E: single dot */}
                <circle cx="56" cy="91" r="2" fill="#78350f"/>
                
                {/* Faded arc to suggest the rest of circle */}
                <path d="M48 90 A42 42 0 0 1 44 9" stroke="#78350f" strokeWidth="1" fill="none" opacity="0.15" strokeDasharray="3 6"/>
                
                {/* Person-antenna figure in center */}
                {/* Head */}
                <circle cx="50" cy="38" r="5" fill="#78350f"/>
                
                {/* Body */}
                <line x1="50" y1="43" x2="50" y2="62"/>
                
                {/* Arms raised (like broadcasting/receiving) */}
                <line x1="50" y1="48" x2="38" y2="40"/>
                <line x1="50" y1="48" x2="62" y2="40"/>
                
                {/* Legs */}
                <line x1="50" y1="62" x2="42" y2="74"/>
                <line x1="50" y1="62" x2="58" y2="74"/>
                
                {/* Radio waves on LEFT side - rotated 45° clockwise, centered at hand (38, 40) */}
                <g transform="rotate(45, 38, 40)">
                  <path d="M34 36 Q30 40, 34 44" fill="none" opacity="0.7"/>
                  <path d="M28 32 Q22 40, 28 48" fill="none" opacity="0.4"/>
                </g>
                
                {/* Bluetooth symbol on RIGHT side - rotated 30° anti-clockwise, aligned with arm direction */}
                <g transform="translate(67, 37) rotate(-30)">
                  <line x1="0" y1="-8" x2="0" y2="8"/>
                  <line x1="0" y1="-8" x2="5" y2="-3"/>
                  <line x1="5" y1="-3" x2="-4" y2="4"/>
                  <line x1="0" y1="8" x2="5" y2="3"/>
                  <line x1="5" y1="3" x2="-4" y2="-4"/>
                </g>
                
                {/* Classic Satellite */}
                <g transform="translate(28, 20) rotate(-25)">
                  {/* Main body */}
                  <rect x="-5" y="-4" width="10" height="8" rx="1" fill="none"/>
                  {/* Left solar panel */}
                  <line x1="-5" y1="0" x2="-9" y2="0"/>
                  <rect x="-17" y="-4" width="8" height="8" fill="none"/>
                  <line x1="-13" y1="-4" x2="-13" y2="4"/>
                  {/* Right solar panel */}
                  <line x1="5" y1="0" x2="9" y2="0"/>
                  <rect x="9" y="-4" width="8" height="8" fill="none"/>
                  <line x1="13" y1="-4" x2="13" y2="4"/>
                  {/* Antenna dish on top */}
                  <path d="M-3 -4 Q0 -9, 3 -4" fill="none"/>
                  <line x1="0" y1="-6" x2="0" y2="-4"/>
                </g>
              </svg>
              <span className="text-amber-900 font-semibold tracking-wide text-lg">geogram</span>
            </div>

            {/* Dark polished version */}
            <div className="bg-slate-900 rounded-2xl p-10 flex flex-col items-center gap-4 border border-slate-800">
              <svg width="160" height="160" viewBox="0 0 100 100" fill="none">
                
                {/* Morse code arc */}
                {/* H: 4 dots - spread along arc */}
                <circle cx="50" cy="8" r="2.5" fill="#22d3ee"/>
                <circle cx="56" cy="8.5" r="2.5" fill="#22d3ee"/>
                <circle cx="62" cy="10" r="2.5" fill="#22d3ee"/>
                <circle cx="68" cy="12" r="2.5" fill="#22d3ee"/>
                
                {/* GAP */}
                
                {/* O: 3 dashes - following the circle curve */}
                <line x1="78" y1="20" x2="82" y2="27" stroke="#22d3ee" strokeWidth="3" strokeLinecap="round"/>
                <line x1="86" y1="34" x2="89" y2="42" stroke="#22d3ee" strokeWidth="3" strokeLinecap="round"/>
                <line x1="91" y1="49" x2="91" y2="57" stroke="#22d3ee" strokeWidth="3" strokeLinecap="round"/>
                
                {/* GAP */}
                
                {/* P: dot dash dash dot */}
                <circle cx="89" cy="68" r="2.5" fill="#22d3ee"/>
                <line x1="87" y1="73" x2="84" y2="78" stroke="#22d3ee" strokeWidth="3" strokeLinecap="round"/>
                <line x1="80" y1="82" x2="75" y2="85" stroke="#22d3ee" strokeWidth="3" strokeLinecap="round"/>
                <circle cx="68" cy="88" r="2.5" fill="#22d3ee"/>
                
                {/* GAP */}
                
                {/* E: single dot */}
                <circle cx="56" cy="91" r="2.5" fill="#22d3ee"/>
                
                <path d="M48 90 A42 42 0 0 1 44 9" stroke="#22d3ee" strokeWidth="1" fill="none" opacity="0.12" strokeDasharray="3 6"/>
                
                {/* Person-antenna */}
                <circle cx="50" cy="38" r="6" fill="#22d3ee"/>
                <line x1="50" y1="44" x2="50" y2="62" stroke="#22d3ee" strokeWidth="2.5"/>
                <line x1="50" y1="49" x2="37" y2="40" stroke="#22d3ee" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="49" x2="63" y2="40" stroke="#22d3ee" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="41" y2="74" stroke="#22d3ee" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="59" y2="74" stroke="#22d3ee" strokeWidth="2.5" strokeLinecap="round"/>
                
                {/* Radio waves on LEFT - rotated 45° clockwise, centered at hand (37, 40) */}
                <g transform="rotate(45, 37, 40)">
                  <path d="M33 36 Q28 40, 33 44" stroke="#22d3ee" strokeWidth="1.5" fill="none" opacity="0.6"/>
                  <path d="M27 32 Q20 40, 27 48" stroke="#22d3ee" strokeWidth="1.5" fill="none" opacity="0.3"/>
                </g>
                
                {/* Bluetooth on RIGHT - rotated 30° anti-clockwise, aligned with arm direction */}
                <g transform="translate(68, 37) rotate(-30)" stroke="#22d3ee" strokeWidth="1.5">
                  <line x1="0" y1="-8" x2="0" y2="8"/>
                  <line x1="0" y1="-8" x2="5" y2="-3"/>
                  <line x1="5" y1="-3" x2="-4" y2="4"/>
                  <line x1="0" y1="8" x2="5" y2="3"/>
                  <line x1="5" y1="3" x2="-4" y2="-4"/>
                </g>
                
                {/* Classic Satellite */}
                <g transform="translate(28, 20) rotate(-25)">
                  <rect x="-5" y="-4" width="10" height="8" rx="1" stroke="#22d3ee" strokeWidth="1.5" fill="none"/>
                  <line x1="-5" y1="0" x2="-9" y2="0" stroke="#22d3ee" strokeWidth="1.5"/>
                  <rect x="-17" y="-4" width="8" height="8" stroke="#22d3ee" strokeWidth="1.5" fill="none"/>
                  <line x1="-13" y1="-4" x2="-13" y2="4" stroke="#22d3ee" strokeWidth="1"/>
                  <line x1="5" y1="0" x2="9" y2="0" stroke="#22d3ee" strokeWidth="1.5"/>
                  <rect x="9" y="-4" width="8" height="8" stroke="#22d3ee" strokeWidth="1.5" fill="none"/>
                  <line x1="13" y1="-4" x2="13" y2="4" stroke="#22d3ee" strokeWidth="1"/>
                  <path d="M-3 -4 Q0 -9, 3 -4" stroke="#22d3ee" strokeWidth="1.5" fill="none"/>
                  <line x1="0" y1="-6" x2="0" y2="-4" stroke="#22d3ee" strokeWidth="1.5"/>
                </g>
              </svg>
              <span className="text-white font-semibold tracking-wide text-lg">geogram</span>
            </div>

            {/* Light version */}
            <div className="bg-white rounded-2xl p-10 flex flex-col items-center gap-4">
              <svg width="160" height="160" viewBox="0 0 100 100" fill="none">
                
                {/* H: 4 dots - spread along arc */}
                <circle cx="50" cy="8" r="2.5" fill="#0891b2"/>
                <circle cx="56" cy="8.5" r="2.5" fill="#0891b2"/>
                <circle cx="62" cy="10" r="2.5" fill="#0891b2"/>
                <circle cx="68" cy="12" r="2.5" fill="#0891b2"/>
                
                {/* GAP */}
                
                {/* O: 3 dashes - following the circle curve */}
                <line x1="78" y1="20" x2="82" y2="27" stroke="#0891b2" strokeWidth="3" strokeLinecap="round"/>
                <line x1="86" y1="34" x2="89" y2="42" stroke="#0891b2" strokeWidth="3" strokeLinecap="round"/>
                <line x1="91" y1="49" x2="91" y2="57" stroke="#0891b2" strokeWidth="3" strokeLinecap="round"/>
                
                {/* GAP */}
                
                {/* P: dot dash dash dot */}
                <circle cx="89" cy="68" r="2.5" fill="#0891b2"/>
                <line x1="87" y1="73" x2="84" y2="78" stroke="#0891b2" strokeWidth="3" strokeLinecap="round"/>
                <line x1="80" y1="82" x2="75" y2="85" stroke="#0891b2" strokeWidth="3" strokeLinecap="round"/>
                <circle cx="68" cy="88" r="2.5" fill="#0891b2"/>
                
                {/* GAP */}
                
                {/* E: single dot */}
                <circle cx="56" cy="91" r="2.5" fill="#0891b2"/>
                
                <path d="M48 90 A42 42 0 0 1 44 9" stroke="#0891b2" strokeWidth="1" fill="none" opacity="0.15" strokeDasharray="3 6"/>
                
                <circle cx="50" cy="38" r="6" fill="#0891b2"/>
                <line x1="50" y1="44" x2="50" y2="62" stroke="#0891b2" strokeWidth="2.5"/>
                <line x1="50" y1="49" x2="37" y2="40" stroke="#0891b2" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="49" x2="63" y2="40" stroke="#0891b2" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="41" y2="74" stroke="#0891b2" strokeWidth="2.5" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="59" y2="74" stroke="#0891b2" strokeWidth="2.5" strokeLinecap="round"/>
                
                {/* Radio waves on LEFT - rotated 45° clockwise, centered at hand (37, 40) */}
                <g transform="rotate(45, 37, 40)">
                  <path d="M33 36 Q28 40, 33 44" stroke="#0891b2" strokeWidth="1.5" fill="none" opacity="0.6"/>
                  <path d="M27 32 Q20 40, 27 48" stroke="#0891b2" strokeWidth="1.5" fill="none" opacity="0.3"/>
                </g>
                
                {/* Bluetooth on RIGHT - rotated 30° anti-clockwise, aligned with arm direction */}
                <g transform="translate(68, 37) rotate(-30)" stroke="#0891b2" strokeWidth="1.5">
                  <line x1="0" y1="-8" x2="0" y2="8"/>
                  <line x1="0" y1="-8" x2="5" y2="-3"/>
                  <line x1="5" y1="-3" x2="-4" y2="4"/>
                  <line x1="0" y1="8" x2="5" y2="3"/>
                  <line x1="5" y1="3" x2="-4" y2="-4"/>
                </g>
                
                {/* Classic Satellite */}
                <g transform="translate(28, 20) rotate(-25)">
                  <rect x="-5" y="-4" width="10" height="8" rx="1" stroke="#0891b2" strokeWidth="1.5" fill="none"/>
                  <line x1="-5" y1="0" x2="-9" y2="0" stroke="#0891b2" strokeWidth="1.5"/>
                  <rect x="-17" y="-4" width="8" height="8" stroke="#0891b2" strokeWidth="1.5" fill="none"/>
                  <line x1="-13" y1="-4" x2="-13" y2="4" stroke="#0891b2" strokeWidth="1"/>
                  <line x1="5" y1="0" x2="9" y2="0" stroke="#0891b2" strokeWidth="1.5"/>
                  <rect x="9" y="-4" width="8" height="8" stroke="#0891b2" strokeWidth="1.5" fill="none"/>
                  <line x1="13" y1="-4" x2="13" y2="4" stroke="#0891b2" strokeWidth="1"/>
                  <path d="M-3 -4 Q0 -9, 3 -4" stroke="#0891b2" strokeWidth="1.5" fill="none"/>
                  <line x1="0" y1="-6" x2="0" y2="-4" stroke="#0891b2" strokeWidth="1.5"/>
                </g>
              </svg>
              <span className="text-slate-800 font-semibold tracking-wide text-lg">geogram</span>
            </div>

            {/* App icon */}
            <div className="rounded-3xl p-6 flex items-center justify-center" style={{background: 'linear-gradient(145deg, #0891b2 0%, #0e7490 100%)'}}>
              <svg width="80" height="80" viewBox="0 0 100 100" fill="none">
                {/* Morse arc simplified with spacing */}
                {/* H: 4 dots - spread along arc */}
                <circle cx="50" cy="8" r="3" fill="white"/>
                <circle cx="57" cy="9" r="3" fill="white"/>
                <circle cx="64" cy="11" r="3" fill="white"/>
                <circle cx="70" cy="14" r="3" fill="white"/>
                {/* GAP then O: 2 dashes - following curve */}
                <line x1="80" y1="24" x2="84" y2="32" stroke="white" strokeWidth="4" strokeLinecap="round"/>
                <line x1="88" y1="42" x2="90" y2="52" stroke="white" strokeWidth="4" strokeLinecap="round"/>
                {/* GAP then P: dot dash dot */}
                <circle cx="90" cy="64" r="3" fill="white"/>
                <line x1="87" y1="72" x2="82" y2="78" stroke="white" strokeWidth="4" strokeLinecap="round"/>
                <circle cx="74" cy="84" r="3" fill="white"/>
                {/* GAP then E: dot */}
                <circle cx="62" cy="90" r="3" fill="white"/>
                
                {/* Person */}
                <circle cx="50" cy="38" r="7" fill="white"/>
                <line x1="50" y1="45" x2="50" y2="62" stroke="white" strokeWidth="3"/>
                <line x1="50" y1="50" x2="38" y2="42" stroke="white" strokeWidth="3" strokeLinecap="round"/>
                <line x1="50" y1="50" x2="62" y2="42" stroke="white" strokeWidth="3" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="42" y2="72" stroke="white" strokeWidth="3" strokeLinecap="round"/>
                <line x1="50" y1="62" x2="58" y2="72" stroke="white" strokeWidth="3" strokeLinecap="round"/>
                
                {/* Radio wave left - rotated 45° clockwise, centered at hand (38, 42) */}
                <g transform="rotate(45, 38, 42)">
                  <path d="M34 38 Q28 42, 34 46" stroke="white" strokeWidth="2" fill="none" opacity="0.7"/>
                </g>
                
                {/* Bluetooth right - rotated 30° anti-clockwise, aligned with arm direction */}
                <g transform="translate(67, 39) rotate(-30)" stroke="white" strokeWidth="2">
                  <line x1="0" y1="-7" x2="0" y2="7"/>
                  <line x1="0" y1="-7" x2="4" y2="-3"/>
                  <line x1="4" y1="-3" x2="-3" y2="3"/>
                  <line x1="0" y1="7" x2="4" y2="3"/>
                  <line x1="4" y1="3" x2="-3" y2="-3"/>
                </g>
              </svg>
            </div>
          </div>
        </section>

        {/* Symbol meaning */}
        <section className="bg-slate-800/50 rounded-2xl p-8 max-w-2xl">
          <h2 className="text-white text-lg font-medium mb-4">Symbol meaning:</h2>
          <ul className="text-slate-300 space-y-3 text-sm">
            <li><span className="text-cyan-400 font-mono">Morse arc (HOPE)</span> — Resilience, amateur radio heritage, hidden message for those who know</li>
            <li><span className="text-cyan-400 font-mono">Person with raised arms</span> — Human at the center, broadcasting & receiving, community</li>
            <li><span className="text-cyan-400 font-mono">Radio waves (left)</span> — FM/APRS transmission, long-range communication</li>
            <li><span className="text-cyan-400 font-mono">Bluetooth (right)</span> — BLE mesh, short-range peer-to-peer, modern tech</li>
            <li><span className="text-cyan-400 font-mono">Classic satellite</span> — Global reach, NOSTR relay concept, sky-based infrastructure</li>
          </ul>
        </section>

      </div>
    </div>
  );
}
