// screens.jsx — Terminal-style secure chat UI screens (modernized)

// ─────────────────────────────────────────────────────────────
// Tokens
// ─────────────────────────────────────────────────────────────
const T = {
  bg:          '#0a0d0b',
  bgDeep:      '#06080706',
  surface:     '#10151210',
  surfaceHi:   '#141a17',
  hairline:    'rgba(180,220,200,0.08)',
  hairlineHi:  'rgba(120,230,170,0.18)',
  green:       '#3df27e',
  greenSoft:   '#7fe0a3',
  greenDim:    'rgba(61,242,126,0.55)',
  greenGhost:  'rgba(61,242,126,0.14)',
  greenGlow:   'rgba(61,242,126,0.32)',
  fg:          '#e2e6e2',
  fgDim:       '#8a918a',
  fgMute:      '#525a52',
  warn:        '#e6c067',
  font:        "'JetBrains Mono', ui-monospace, Menlo, monospace",
  // radii — modernization
  rSm: 8,
  rMd: 12,
  rLg: 16,
  rXl: 22,
};

// ─────────────────────────────────────────────────────────────
// Screen base — vignette + scanline + faint noise
// ─────────────────────────────────────────────────────────────
function ScreenBase({ children, accent = T.green }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: T.bg,
      color: T.fg,
      fontFamily: T.font,
      overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(140% 90% at 50% -10%, ${accent}14 0%, transparent 55%), radial-gradient(120% 100% at 50% 100%, #00000080 0%, transparent 60%)`,
      }} />
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        backgroundImage: 'repeating-linear-gradient(to bottom, rgba(255,255,255,0.018) 0 1px, transparent 1px 3px)',
        mixBlendMode: 'overlay',
        opacity: 0.5,
      }} />
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.035,
        backgroundImage: `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 1 0'/></filter><rect width='100%' height='100%' filter='url(%23n)'/></svg>")`,
      }} />
      <div style={{ position: 'relative', height: '100%', width: '100%' }}>
        {children}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
function TermHeader({ left, right, accent = T.green }) {
  return (
    <div style={{
      padding: '54px 22px 14px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      borderBottom: `1px solid ${T.hairline}`,
      fontSize: 11, letterSpacing: '0.14em', textTransform: 'uppercase',
      color: T.fgDim,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Pulse color={accent} />
        <span>{left}</span>
      </div>
      <div style={{ color: T.fgMute }}>{right}</div>
    </div>
  );
}

function Pulse({ color = T.green, size = 6 }) {
  return (
    <span style={{
      display: 'inline-block', width: size, height: size, borderRadius: '50%',
      background: color, boxShadow: `0 0 10px ${color}`,
      animation: 'sc-pulse 1.6s ease-in-out infinite',
    }} />
  );
}

// ─────────────────────────────────────────────────────────────
// Modern button — pill-ish, soft accent fill
// ─────────────────────────────────────────────────────────────
function TermButton({ children, primary = false, accent = T.green, sub, onClick, height = 56 }) {
  return (
    <button onClick={onClick} style={{
      display: 'block', width: '100%',
      minHeight: height,
      padding: '0 20px',
      background: primary ? accent : T.surfaceHi,
      color: primary ? '#06180e' : T.fg,
      border: `1px solid ${primary ? accent : T.hairlineHi}`,
      borderRadius: T.rLg,
      fontFamily: T.font,
      fontSize: 14, letterSpacing: '0.04em',
      textTransform: 'uppercase',
      cursor: 'pointer',
      textAlign: 'left',
      position: 'relative',
      boxShadow: primary ? `0 6px 24px -8px ${accent}80, inset 0 1px 0 ${accent}` : 'inset 0 1px 0 rgba(255,255,255,0.03)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
        <span style={{ fontWeight: 600 }}>{children}</span>
        <span style={{ opacity: 0.7, fontSize: 12 }}>{primary ? '↵' : '→'}</span>
      </div>
      {sub && (
        <div style={{
          marginTop: 4,
          fontSize: 11, color: primary ? '#06180eaa' : T.fgDim,
          textTransform: 'none', letterSpacing: '0.01em',
        }}>{sub}</div>
      )}
    </button>
  );
}

function Caret({ color = T.green, size = 14 }) {
  return (
    <span style={{
      display: 'inline-block', width: 8, height: size, marginLeft: 2,
      background: color, verticalAlign: 'middle', borderRadius: 1,
      animation: 'sc-blink 1s steps(1) infinite',
    }} />
  );
}

// Reusable card with rounded corners
function Card({ children, style, dashed }) {
  return (
    <div style={{
      border: `1px ${dashed ? 'dashed' : 'solid'} ${T.hairline}`,
      borderRadius: T.rMd,
      background: T.surface,
      ...style,
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN 1 — HOME
// ─────────────────────────────────────────────────────────────
function HomeScreen({ accent = T.green }) {
  return (
    <ScreenBase accent={accent}>
      <TermHeader left="SECRET / v0.4.1" right="OFFLINE • E2EE" accent={accent} />

      <div style={{ padding: '36px 22px 0' }}>
        <div style={{ fontSize: 11, color: T.fgMute, letterSpacing: '0.18em' }}>// SESSION</div>
        <div style={{ marginTop: 14, fontSize: 30, lineHeight: 1.15, color: T.fg, letterSpacing: '-0.015em', fontWeight: 500 }}>
          No accounts.<br />
          No history.<br />
          <span style={{ color: accent }}>No trace<Caret color={accent} /></span>
        </div>
        <div style={{ marginTop: 18, fontSize: 12.5, color: T.fgDim, lineHeight: 1.6 }}>
          Rooms exist only while open. Close the<br />app — the keys are gone with you.
        </div>
      </div>

      <Card style={{ margin: '28px 22px 0', padding: '14px 16px', fontSize: 11.5, lineHeight: 1.9, color: T.fgDim }}>
        <Diag label="entropy"   value="OK"   ok accent={accent} />
        <Diag label="transport" value="TLS 1.3 / TOR-OK" ok accent={accent} />
        <Diag label="storage"   value="MEMORY-ONLY" ok accent={accent} />
        <Diag label="identity"  value="—" ok accent={accent} />
      </Card>

      <div style={{ position: 'absolute', left: 22, right: 22, bottom: 60, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <TermButton primary accent={accent} sub="Generates a new code + key pair">Create Room</TermButton>
        <TermButton accent={accent} sub="Enter a code shared with you">Join Room</TermButton>
        <div style={{ marginTop: 6, textAlign: 'center', fontSize: 10, color: T.fgMute, letterSpacing: '0.16em' }}>
          NOTHING IS SAVED · NOTHING IS LOGGED
        </div>
      </div>
    </ScreenBase>
  );
}

function Diag({ label, value, ok, accent }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: T.font }}>
      <span><span style={{ color: T.fgMute }}>›</span> {label}</span>
      <span style={{ color: ok ? accent : T.warn }}>{value}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN 2 — JOIN ROOM (code + nickname + password)
// ─────────────────────────────────────────────────────────────
function JoinScreen({ accent = T.green, nickname = 'a.b.', hasPw = true }) {
  return (
    <ScreenBase accent={accent}>
      <TermHeader left="‹ BACK   /   JOIN" right="STEP 1 / 2" accent={accent} />

      <div style={{ padding: '28px 22px 0' }}>
        {/* Code */}
        <div style={{ fontSize: 11, color: T.fgMute, letterSpacing: '0.18em' }}>// ROOM CODE</div>
        <div style={{ marginTop: 18, display: 'flex', alignItems: 'center', gap: 8 }}>
          <CodeBlock chars="WOLF" filled accent={accent} />
          <span style={{ color: T.fgMute, fontSize: 18 }}>—</span>
          <CodeBlock chars="7342" filled accent={accent} cursor />
        </div>

        {/* Nickname — NEW */}
        <div style={{ marginTop: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 11, color: T.fgMute, letterSpacing: '0.18em' }}>// NICKNAME <span>(OPTIONAL)</span></div>
            <div style={{ fontSize: 10, color: T.fgMute, letterSpacing: '0.12em' }}>LOCAL ONLY</div>
          </div>
          <div style={{
            marginTop: 10,
            border: `1px solid ${nickname ? T.hairlineHi : T.hairline}`,
            borderRadius: T.rMd,
            background: T.surface,
            padding: '14px 16px',
            display: 'flex', alignItems: 'center', gap: 10,
            minHeight: 52,
          }}>
            <span style={{ color: T.fgMute }}>@</span>
            {nickname
              ? <span style={{ color: T.fg, fontSize: 15 }}>{nickname}</span>
              : <span style={{ color: T.fgMute, fontSize: 13 }}>e.g. a.b. · knight · m</span>
            }
            <Caret color={accent} />
            <span style={{ marginLeft: 'auto', fontSize: 10, color: T.fgMute, letterSpacing: '0.1em' }}>FALLBACK · PEER</span>
          </div>
          <div style={{ marginTop: 8, fontSize: 11, color: T.fgDim, lineHeight: 1.55 }}>
            Shown to your peer instead of <span style={{ color: T.fg }}>PEER</span>.<br />
            Leave blank to stay fully anonymous.
          </div>
        </div>

        {/* Password */}
        <div style={{ marginTop: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 11, color: T.fgMute, letterSpacing: '0.18em' }}>// PASSWORD <span>(OPTIONAL)</span></div>
            <div style={{ fontSize: 10, color: T.fgMute, letterSpacing: '0.12em' }}>CASE-SENSITIVE</div>
          </div>
          <div style={{
            marginTop: 10,
            border: `1px solid ${hasPw ? T.hairlineHi : T.hairline}`,
            borderRadius: T.rMd,
            background: T.surface,
            padding: '14px 16px',
            display: 'flex', alignItems: 'center', gap: 10,
            minHeight: 52,
          }}>
            <span style={{ color: T.fgMute }}>$</span>
            {hasPw
              ? <span style={{ color: accent, letterSpacing: '0.4em', fontSize: 14 }}>•••••••••</span>
              : <span style={{ color: T.fgMute, fontSize: 13 }}>type to derive a key</span>
            }
            <Caret color={accent} />
            <span style={{ marginLeft: 'auto', fontSize: 10, color: T.fgMute }}>SHA-256 ▸ AES-256</span>
          </div>
        </div>
      </div>

      <div style={{ position: 'absolute', left: 22, right: 22, bottom: 56, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <TermButton primary accent={accent} sub="Verifies the room and derives the shared key">Connect</TermButton>
      </div>
    </ScreenBase>
  );
}

function CodeBlock({ chars, accent, cursor }) {
  const slots = chars.split('');
  while (slots.length < 4) slots.push('');
  return (
    <div style={{ display: 'flex', gap: 8, flex: 1 }}>
      {slots.map((ch, i) => (
        <div key={i} style={{
          flex: 1, height: 56, display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: `1px solid ${ch ? T.hairlineHi : T.hairline}`,
          borderRadius: T.rMd,
          color: ch ? accent : T.fgMute,
          fontSize: 22, fontWeight: 600,
          background: ch ? `${accent}10` : T.surface,
          position: 'relative',
        }}>
          {ch || <span style={{ color: T.fgMute, fontSize: 14 }}>_</span>}
          {cursor && i === slots.length - 1 && ch && (
            <span style={{ position: 'absolute', right: 6, bottom: 8, width: 6, height: 2, background: accent, borderRadius: 1, animation: 'sc-blink 1s steps(1) infinite' }} />
          )}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN 3 — CHAT (no timestamps, no typing indicator)
// ─────────────────────────────────────────────────────────────
const SAMPLE_MESSAGES = [
  { side: 'sys',  text: '— session opened —' },
  { side: 'sys',  text: 'peer joined · key verified ✓' },
  { side: 'them', text: 'are you there' },
  { side: 'me',   text: 'yes. line is clean.' },
  { side: 'them', text: 'good. send the doc reference.' },
  { side: 'me',   text: 'check your earlier note.\nfourth paragraph, second line.' },
  { side: 'them', text: 'got it.' },
  { side: 'them', text: 'when this room closes — gone, right?' },
  { side: 'me',   text: 'gone. no logs, no backups.' },
];

function ChatScreen({ accent = T.green, showKb = false, peerLabel = 'PEER', myLabel = 'YOU' }) {
  return (
    <ScreenBase accent={accent}>
      <div style={{
        padding: '54px 18px 12px',
        borderBottom: `1px solid ${T.hairline}`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ color: T.fgMute, fontSize: 18 }}>‹</span>
            <span style={{ fontSize: 13, color: T.fg, letterSpacing: '0.1em', fontWeight: 600 }}>WOLF-7342</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 10, letterSpacing: '0.16em', color: T.fgDim }}>
            <Pulse color={accent} />
            <span>ENCRYPTED</span>
          </div>
        </div>
        <div style={{ marginTop: 6, fontSize: 10, color: T.fgMute, letterSpacing: '0.12em', display: 'flex', justifyContent: 'space-between' }}>
          <span>FP 4F:9A:21:C0</span>
          <span>{peerLabel === 'PEER' ? 'ANONYMOUS' : `WITH @${peerLabel.toLowerCase()}`}</span>
        </div>
      </div>

      <div style={{
        position: 'absolute', left: 0, right: 0,
        top: 110,
        bottom: showKb ? 380 : 116,
        overflow: 'hidden',
        padding: '16px 16px 8px',
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        {SAMPLE_MESSAGES.map((m, i) => (
          <Bubble key={i} {...m} accent={accent} peerLabel={peerLabel} myLabel={myLabel} />
        ))}
      </div>

      <div style={{
        position: 'absolute', left: 0, right: 0,
        bottom: showKb ? 336 : 34,
        borderTop: `1px solid ${T.hairline}`,
        background: T.bg,
        padding: '12px 14px',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          border: `1px solid ${T.hairlineHi}`,
          background: T.surface,
          borderRadius: T.rXl,
          padding: '12px 16px',
          minHeight: 50,
          fontFamily: T.font,
        }}>
          <span style={{ color: accent, fontSize: 13 }}>›</span>
          <span style={{ color: T.fg, fontSize: 14, flex: 1 }}>
            {showKb ? 'gone. no logs, no backups' : 'message'}<Caret color={accent} />
          </span>
          <span style={{
            fontSize: 11, color: '#06180e', letterSpacing: '0.14em',
            background: accent, padding: '6px 10px', borderRadius: T.rSm,
            fontWeight: 600,
          }}>SEND</span>
        </div>
        <div style={{ marginTop: 6, display: 'flex', justifyContent: 'space-between', fontSize: 10, color: T.fgMute, letterSpacing: '0.1em' }}>
          <span>AES-256-GCM</span>
          <span>{showKb ? '38 / 4096' : 'TAP TO TYPE'}</span>
        </div>
      </div>

      {showKb && <FakeKeyboard />}
    </ScreenBase>
  );
}

function Bubble({ side, text, accent, peerLabel, myLabel }) {
  if (side === 'sys') {
    return (
      <div style={{ alignSelf: 'center', fontSize: 10, color: T.fgMute, letterSpacing: '0.14em', textAlign: 'center', padding: '6px 0' }}>
        {text}
      </div>
    );
  }
  const me = side === 'me';
  const label = me ? myLabel : peerLabel;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: me ? 'flex-end' : 'flex-start' }}>
      <div style={{
        fontSize: 9.5, color: T.fgMute, letterSpacing: '0.16em',
        marginBottom: 4, paddingLeft: me ? 0 : 4, paddingRight: me ? 4 : 0,
      }}>{label.toUpperCase()}</div>
      <div style={{
        maxWidth: '78%',
        padding: '10px 14px',
        border: `1px solid ${me ? accent + '55' : T.hairlineHi}`,
        background: me ? `${accent}14` : T.surface,
        color: T.fg,
        fontSize: 14, lineHeight: 1.45,
        whiteSpace: 'pre-wrap',
        // asymmetric radii — modern chat feel
        borderRadius: me
          ? `${T.rLg}px ${T.rLg}px ${T.rSm-2}px ${T.rLg}px`
          : `${T.rLg}px ${T.rLg}px ${T.rLg}px ${T.rSm-2}px`,
      }}>
        {text}
      </div>
    </div>
  );
}

function FakeKeyboard() {
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 34,
      height: 302,
      background: '#0d110f',
      borderTop: `1px solid ${T.hairline}`,
      padding: '10px 6px 14px',
      display: 'flex', flexDirection: 'column', gap: 6,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-around', padding: '4px 0 8px', fontSize: 11.5, color: T.fgDim, borderBottom: `1px solid ${T.hairline}` }}>
        <span>backups</span>
        <span style={{ color: T.fg }}>"backups"</span>
        <span>backup</span>
      </div>
      {rows.map((r, i) => (
        <div key={i} style={{ display: 'flex', gap: 5, justifyContent: 'center', paddingLeft: i === 1 ? 16 : 0, paddingRight: i === 1 ? 16 : 0 }}>
          {i === 2 && <KbKey wide>⇧</KbKey>}
          {r.split('').map(ch => <KbKey key={ch}>{ch}</KbKey>)}
          {i === 2 && <KbKey wide>⌫</KbKey>}
        </div>
      ))}
      <div style={{ display: 'flex', gap: 5, marginTop: 2 }}>
        <KbKey extra>123</KbKey>
        <KbKey extra>,</KbKey>
        <KbKey flex>space</KbKey>
        <KbKey extra>.</KbKey>
        <KbKey extra accent>↵</KbKey>
      </div>
    </div>
  );
}

function KbKey({ children, wide, flex, extra, accent: ac }) {
  return (
    <div style={{
      flex: flex ? 4 : (wide ? 1.4 : (extra ? 1.2 : 1)),
      minWidth: wide ? 36 : 28,
      height: 40,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: ac ? `${T.green}18` : 'rgba(255,255,255,0.04)',
      border: `1px solid ${ac ? T.greenGlow : 'rgba(255,255,255,0.06)'}`,
      borderRadius: 8,
      color: ac ? T.green : T.fg,
      fontSize: 14,
      fontFamily: T.font,
    }}>{children}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN — ROOM CREATED
// ─────────────────────────────────────────────────────────────
function CreatedScreen({ accent = T.green }) {
  return (
    <ScreenBase accent={accent}>
      <TermHeader left="ROOM CREATED" right="WAITING FOR PEER" accent={accent} />
      <div style={{ padding: '28px 22px 0' }}>
        <div style={{ fontSize: 11, color: T.fgMute, letterSpacing: '0.18em' }}>// SHARE THIS CODE</div>
        <Card style={{
          marginTop: 14, padding: '26px 16px',
          textAlign: 'center',
          borderColor: T.hairlineHi,
          background: `linear-gradient(180deg, ${T.surfaceHi}, ${T.surface})`,
        }}>
          <div style={{ color: accent, fontSize: 38, letterSpacing: '0.18em', fontWeight: 600, textShadow: `0 0 14px ${T.greenGlow}` }}>
            WOLF<span style={{ color: T.fgMute }}>—</span>7342
          </div>
          <div style={{ marginTop: 10, fontSize: 10, color: T.fgMute, letterSpacing: '0.18em' }}>
            EXPIRES IN <span style={{ color: T.fg }}>09:42</span>
          </div>
        </Card>

        <div style={{ marginTop: 18, fontSize: 12.5, color: T.fgDim, lineHeight: 1.6 }}>
          Share this code through any channel<br />
          <span style={{ color: T.fgMute }}>outside</span> this app. Then optionally<br />
          set a nickname and a password.
        </div>

        <Card style={{ marginTop: 18, padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Step n="01" t="Send the code" />
          <Step n="02" t="Set a nickname (optional)" />
          <Step n="03" t="Agree on a password (optional)" />
          <Step n="04" t="Wait — peer will appear here" accent={accent} live />
        </Card>
      </div>

      <div style={{ position: 'absolute', left: 22, right: 22, bottom: 56, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <TermButton primary accent={accent} sub="Locks the code to a single peer">Set Nickname & Password</TermButton>
        <TermButton accent={accent}>Cancel Room</TermButton>
      </div>
    </ScreenBase>
  );
}

function Step({ n, t, accent, live }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 12.5, color: live ? T.fg : T.fgDim }}>
      <span style={{ color: live ? accent : T.fgMute, letterSpacing: '0.1em' }}>{n}</span>
      <span style={{ flex: 1 }}>{t}</span>
      {live && <Pulse color={accent} />}
    </div>
  );
}

// Expose
Object.assign(window, {
  T, ScreenBase, TermHeader, TermButton, Caret, Pulse, Card,
  HomeScreen, JoinScreen, ChatScreen, CreatedScreen,
});
