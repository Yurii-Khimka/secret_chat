// app.jsx — Mounts the design canvas with all phone screens

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "tone": "mint",
  "nickname": "a.b.",
  "showAnonChat": true
}/*EDITMODE-END*/;

const ACCENTS = {
  ice:    '#a8e8e0',  // soft ice
  indigo: '#9aa6ff',  // soft indigo
  sand:   '#e8d49a',  // soft sand
  lime:   '#c8f08a',  // soft lime
  mint:   '#7fe0a3',  // soft mint
};

function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const accent = ACCENTS[tweaks.tone] || ACCENTS.mint;
  const nick = (tweaks.nickname || '').trim();
  const peerLabel = nick ? nick : 'PEER';

  const Frame = ({ children }) => (
    <IOSDevice width={402} height={874} dark>
      <div style={{ position: 'relative', width: '100%', height: '100%' }}>
        {children}
      </div>
    </IOSDevice>
  );

  return (
    <>
      <GlobalStyles />
      <DesignCanvas>
        <DCSection id="flow" title="Core flow" subtitle="Modernized · soft radii · nickname-aware">
          <DCArtboard id="home" label="01 · Home" width={402} height={874}>
            <Frame><HomeScreen accent={accent} /></Frame>
          </DCArtboard>
          <DCArtboard id="created" label="02 · Room created (host)" width={402} height={874}>
            <Frame><CreatedScreen accent={accent} /></Frame>
          </DCArtboard>
          <DCArtboard id="join" label="03 · Join — with nickname" width={402} height={874}>
            <Frame><JoinScreen accent={accent} nickname={nick} /></Frame>
          </DCArtboard>
          <DCArtboard id="chat-named" label={`04 · Chat — labeled as ${peerLabel.toUpperCase()}`} width={402} height={874}>
            <Frame><ChatScreen accent={accent} showKb={false} peerLabel={peerLabel} myLabel="YOU" /></Frame>
          </DCArtboard>
          <DCArtboard id="chat-anon" label="05 · Chat (anonymous · PEER)" width={402} height={874}>
            <Frame><ChatScreen accent={accent} showKb={false} peerLabel="PEER" myLabel="YOU" /></Frame>
          </DCArtboard>
          <DCArtboard id="chat-typing" label="06 · Chat (composing)" width={402} height={874}>
            <Frame><ChatScreen accent={accent} showKb={true} peerLabel={peerLabel} myLabel="YOU" /></Frame>
          </DCArtboard>
        </DCSection>

        <DCSection id="notes" title="Design notes">
          <DCArtboard id="system" label="System rationale" width={520} height={874}>
            <NotesPanel accent={accent} />
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Identity">
          <TweakText
            label="Nickname"
            value={tweaks.nickname || ''}
            placeholder="leave blank → PEER"
            onChange={v => setTweak('nickname', v)}
          />
        </TweakSection>
        <TweakSection label="Tone">
          <TweakSelect
            label="Accent"
            value={tweaks.tone}
            options={[
              { value: 'ice',    label: 'Ice' },
              { value: 'indigo', label: 'Indigo' },
              { value: 'sand',   label: 'Sand' },
              { value: 'lime',   label: 'Lime' },
              { value: 'mint',   label: 'Mint' },
            ]}
            onChange={v => setTweak('tone', v)}
          />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

function NotesPanel({ accent }) {
  const card = {
    background: T.bg, color: T.fg, fontFamily: T.font,
    padding: 28, height: '100%', overflow: 'auto',
    fontSize: 13, lineHeight: 1.6,
  };
  const h = { fontSize: 11, color: T.fgDim, letterSpacing: '0.18em', marginTop: 18, marginBottom: 8 };
  return (
    <div style={card}>
      <div style={{ fontSize: 16, color: accent, letterSpacing: '0.1em' }}>// SECRET — DESIGN NOTES</div>

      <div style={h}>PRINCIPLES</div>
      <div>· Mono everywhere. Color is reserved.</div>
      <div>· Soft radii (8 / 12 / 16 / 22) — modern but cold.</div>
      <div>· No timestamps. No typing indicator. Less surface = less leak.</div>

      <div style={h}>IDENTITY</div>
      <div>· Nickname is optional, local-only — it never leaves the device beyond the encrypted stream.</div>
      <div>· Default fallback is the literal label <span style={{ color: accent }}>PEER</span>.</div>
      <div>· Examples: <span style={{ color: T.fg }}>a.b.</span> · <span style={{ color: T.fg }}>knight</span> · <span style={{ color: T.fg }}>m</span>.</div>

      <div style={h}>HIT TARGETS</div>
      <div>· Buttons ≥ 56px tall. Inputs ≥ 52px.</div>
      <div>· Send action is a tappable pill, not just a glyph.</div>

      <div style={h}>FEEDBACK</div>
      <div>· Pulse dot = live signal.</div>
      <div>· Caret = the user's locus of attention.</div>

      <div style={h}>DELIBERATELY OMITTED</div>
      <div>· Avatars. Read receipts. Timestamps in bubbles.</div>
      <div>· "Peer is typing" — out of scope, out of trust model.</div>
      <div>· Reactions, attachments, threads.</div>
    </div>
  );
}

function GlobalStyles() {
  return (
    <style>{`
      @keyframes sc-pulse {
        0%, 100% { opacity: 1; transform: scale(1); }
        50%      { opacity: 0.35; transform: scale(0.85); }
      }
      @keyframes sc-blink {
        0%, 49%   { opacity: 1; }
        50%, 100% { opacity: 0; }
      }
      ::selection { background: ${ACCENTS.mint}; color: #000; }
      body { background: #050605; }
    `}</style>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
