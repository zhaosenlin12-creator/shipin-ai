import React, {useMemo} from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {Audio, Video} from '@remotion/media';

type AccentName = 'blue' | 'cyan' | 'green' | 'red' | 'purple';
type Scene = {
  id: string;
  start: number;
  duration: number;
  layout: string;
  tone: AccentName;
  caption: {zh: string; en: string};
  chapter: {eyebrow: string; title: string; accent: AccentName};
  visual: {
    type: 'presenter' | 'broll' | 'chapter-list' | 'grid';
    asset?: string;
    motion?: 'push-in' | 'drift-left' | 'drift-right' | 'pan-up' | 'pan-left' | 'pan-right';
    items?: string[];
    fill?: number;
  };
  card?: {
    type: 'stat' | 'chat' | 'warning' | 'bars' | 'flow';
    label: string;
    value?: string;
    accent?: AccentName;
    rows?: string[];
    values?: number[];
  };
};

export type Timeline = {
  fps: number;
  width: number;
  height: number;
  targetDurationSeconds: number;
  style: {
    palette: Record<string, string>;
    caption: {fontFamily: string; fontSize: number; englishSize: number; shadow: string};
  };
  scenes: Scene[];
};

type Props = {timeline: Timeline};

const palette: Record<string, string> = {
  ink: '#f4f7fa',
  muted: '#a9b5bf',
  blue: '#39b9ff',
  cyan: '#55f0d1',
  green: '#55e37b',
  red: '#ff5c64',
  purple: '#ad7cff',
  panel: '#091016',
};

const sceneAt = (scenes: Scene[], seconds: number) =>
  scenes.find((scene) => seconds >= scene.start && seconds < scene.start + scene.duration) ??
  scenes[scenes.length - 1];

const accentColor = (accent: AccentName) => palette[accent];

const enter = (frame: number, duration = 18) =>
  interpolate(frame, [0, duration], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

const PresenterPlate: React.FC<{scene: Scene; localFrame: number; fps: number}> = ({
  scene,
  localFrame,
  fps,
}) => {
  const motion = scene.visual.motion ?? 'push-in';
  const segmentStart = scene.start < 60 ? 0 : 60;
  const videoAsset = scene.start < 60
    ? 'generated/avatar-lipsync-0-60.mp4'
    : 'generated/avatar-lipsync-60-120.mp4';
  const trimBefore = Math.max(0, Math.round((scene.start - segmentStart) * fps));
  const progress = interpolate(localFrame, [0, scene.duration * fps], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
  const breath = Math.sin(localFrame * 0.045) * 1.8;
  const scale = motion === 'push-in' ? 1.02 + progress * 0.05 : 1.04 + progress * 0.025;
  const x =
    motion === 'drift-left' || motion === 'pan-left'
      ? progress * -18 + breath
      : motion === 'drift-right'
        ? progress * 18 + breath
        : breath;
  const y = motion === 'pan-up' ? progress * -14 + Math.sin(localFrame * 0.038) * 1.1 : Math.sin(localFrame * 0.038) * 1.1;
  const mouthPulse =
    0.42 +
    Math.max(0, Math.sin(localFrame * 0.62 + scene.start * 0.9)) * 0.36 +
    Math.max(0, Math.sin(localFrame * 0.27 + 1.4)) * 0.22;
  const mouthOpacity = Math.min(0.92, mouthPulse) * enter(localFrame, 8);
  return (
    <div
      style={{
        ...styles.media,
        transform: `scale(${scale}) translate(${x}px, ${y}px)`,
      }}
    >
      <Video
        src={staticFile(videoAsset)}
        trimBefore={trimBefore}
        muted
        playsInline
        style={styles.media}
        volume={0}
      />
    </div>
  );
};

const BrollPlate: React.FC<{scene: Scene; localFrame: number; fps: number}> = ({
  scene,
  localFrame,
  fps,
}) => {
  const progress = interpolate(localFrame, [0, scene.duration * fps], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });
  const motion = scene.visual.motion ?? 'push-in';
  const scale = motion === 'push-in' ? 1.01 + progress * 0.06 : 1.04;
  const x = motion === 'pan-left' ? progress * -24 : motion === 'pan-right' ? progress * 24 : 0;
  const y = motion === 'pan-up' ? progress * -16 : 0;
  return (
    <Img
      src={staticFile(scene.visual.asset ?? 'generated/broll-data-center.png')}
      style={{
        ...styles.media,
        opacity: 1,
        transform: `scale(${scale}) translate(${x}px, ${y}px)`,
      }}
    />
  );
};

const GlowLayer: React.FC<{tone: AccentName; localFrame: number}> = ({tone, localFrame}) => {
  const color = accentColor(tone);
  const opacity = interpolate(localFrame, [0, 20], [0, 0.42], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return (
    <>
      <div style={{...styles.glow, background: color, opacity}} />
      <div style={{...styles.vignette, opacity: 0.58 + opacity * 0.15}} />
    </>
  );
};

const ChapterHeader: React.FC<{scene: Scene; localFrame: number}> = ({scene, localFrame}) => {
  const color = accentColor(scene.chapter.accent);
  const progress = enter(localFrame, 15);
  return (
    <div style={{...styles.chapter, opacity: progress, transform: `translateY(${(1 - progress) * 10}px)`}}>
      <div style={{...styles.eyebrow, color}}>
        <span style={{...styles.eyebrowDot, background: color}} />
        {scene.chapter.eyebrow}
      </div>
      <div style={styles.chapterTitle}>{scene.chapter.title}</div>
    </div>
  );
};

const StatCard: React.FC<{card: NonNullable<Scene['card']>; localFrame: number}> = ({card, localFrame}) => {
  const color = accentColor(card.accent ?? 'blue');
  const progress = enter(localFrame, 20);
  return (
    <div style={{...styles.card, borderColor: color, opacity: progress, transform: `translateX(${(1 - progress) * 24}px)`}}>
      <div style={{...styles.cardLabel, color}}>{card.label}</div>
      <div style={styles.statValue}>{card.value}</div>
      <div style={{...styles.statRule, background: color}} />
    </div>
  );
};

const ListCard: React.FC<{card: NonNullable<Scene['card']>; localFrame: number}> = ({card, localFrame}) => {
  const color = accentColor(card.accent ?? (card.type === 'warning' ? 'red' : 'green'));
  const rows = card.rows ?? [];
  const progress = enter(localFrame, 18);
  return (
    <div style={{...styles.card, borderColor: color, opacity: progress, transform: `translateX(${(1 - progress) * 28}px)`}}>
      <div style={{...styles.cardLabel, color}}>{card.label}</div>
      <div style={styles.rows}>
        {rows.map((row, index) => {
          const rowProgress = interpolate(localFrame, [index * 4, index * 4 + 10], [0.2, 1], {
            extrapolateLeft: 'clamp',
            extrapolateRight: 'clamp',
          });
          return (
            <div key={row} style={{...styles.row, opacity: rowProgress}}>
              <span style={{...styles.rowIndex, color}}>{String(index + 1).padStart(2, '0')}</span>
              <span>{row}</span>
              <i style={{...styles.rowBar, background: color, width: `${36 + index * 22}%`}} />
            </div>
          );
        })}
      </div>
    </div>
  );
};

const BarsCard: React.FC<{card: NonNullable<Scene['card']>; localFrame: number}> = ({card, localFrame}) => {
  const color = accentColor(card.accent ?? 'green');
  const values = card.values ?? [36, 58, 82];
  const progress = enter(localFrame, 18);
  return (
    <div style={{...styles.card, borderColor: color, opacity: progress, transform: `translateX(${(1 - progress) * 24}px)`}}>
      <div style={{...styles.cardLabel, color}}>{card.label}</div>
      <div style={styles.bars}>
        {values.map((value, index) => (
          <div key={`${value}-${index}`} style={styles.barRow}>
            <span style={styles.barKey}>{`0${index + 1}`}</span>
            <div style={styles.barTrack}>
              <i style={{...styles.barFill, width: `${Math.round(value * progress)}%`, background: color}} />
            </div>
            <b style={{...styles.barValue, color}}>{value}%</b>
          </div>
        ))}
      </div>
    </div>
  );
};

const FlowCard: React.FC<{card: NonNullable<Scene['card']>; localFrame: number}> = ({card, localFrame}) => {
  const color = accentColor(card.accent ?? 'blue');
  const rows = card.rows ?? [];
  const progress = enter(localFrame, 18);
  return (
    <div style={{...styles.card, borderColor: color, opacity: progress, transform: `translateX(${(1 - progress) * 24}px)`}}>
      <div style={{...styles.cardLabel, color}}>{card.label}</div>
      <div style={styles.flow}>
        {rows.map((row, index) => (
          <React.Fragment key={row}>
            <div style={{...styles.flowNode, borderColor: color, color, opacity: interpolate(localFrame, [index * 4, index * 4 + 10], [0.15, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}}>
              {row}
            </div>
            {index < rows.length - 1 ? <span style={{...styles.flowArrow, color}}>→</span> : null}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
};

const OverlayCard: React.FC<{scene: Scene; localFrame: number}> = ({scene, localFrame}) => {
  if (!scene.card) return null;
  if (scene.card.type === 'stat') return <StatCard card={scene.card} localFrame={localFrame} />;
  if (scene.card.type === 'bars') return <BarsCard card={scene.card} localFrame={localFrame} />;
  if (scene.card.type === 'flow') return <FlowCard card={scene.card} localFrame={localFrame} />;
  return <ListCard card={scene.card} localFrame={localFrame} />;
};

const GridPanel: React.FC<{scene: Scene; localFrame: number}> = ({scene, localFrame}) => {
  const fill = scene.visual.fill ?? 0.5;
  const progress = interpolate(localFrame, [0, 28], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  const cells = useMemo(() => Array.from({length: 240}, (_, index) => index), []);
  const active = Math.round(cells.length * fill * progress);
  const color = accentColor(scene.chapter.accent);
  return (
    <div style={styles.gridPanel}>
      <div style={styles.gridMeta}>
        <span style={{color}}>GLOBAL / POPULATION</span>
        <span style={styles.gridMetaRight}>2,500 CELLS</span>
      </div>
      <div style={styles.grid}>
        {cells.map((cell) => (
          <span key={cell} style={{...styles.cell, background: cell < active ? color : 'rgba(255,255,255,.08)', opacity: cell < active ? 0.9 : 0.52}} />
        ))}
      </div>
    </div>
  );
};

const Caption: React.FC<{scene: Scene; localFrame: number; timeline: Timeline}> = ({scene, localFrame, timeline}) => {
  const progress = enter(localFrame, 12);
  return (
    <div style={{...styles.caption, fontFamily: timeline.style.caption.fontFamily, opacity: progress, transform: `translateY(${(1 - progress) * 12}px)`}}>
      <div>{scene.caption.zh}</div>
      <small>{scene.caption.en}</small>
    </div>
  );
};

export const SourceStyleVideo: React.FC<Props> = ({timeline}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const seconds = frame / fps;
  const scene = sceneAt(timeline.scenes, seconds);
  const localFrame = Math.max(0, frame - Math.round(scene.start * fps));
  const sceneIndex = timeline.scenes.findIndex((candidate) => candidate.id === scene.id);
  const accent = accentColor(scene.tone);

  return (
    <AbsoluteFill style={styles.root}>
      <AbsoluteFill style={{background: palette.panel}} />
      {scene.visual.type === 'presenter' ? <PresenterPlate scene={scene} localFrame={localFrame} fps={fps} /> : null}
      {scene.visual.type === 'broll' ? <BrollPlate scene={scene} localFrame={localFrame} fps={fps} /> : null}
      {scene.visual.type === 'grid' ? <GridPanel scene={scene} localFrame={localFrame} /> : null}
      {scene.visual.type === 'chapter-list' ? <ChapterList scene={scene} localFrame={localFrame} /> : null}
      <GlowLayer tone={scene.tone} localFrame={localFrame} />
      <ChapterHeader scene={scene} localFrame={localFrame} />
      {scene.visual.type !== 'grid' && scene.visual.type !== 'chapter-list' ? (
        <div style={styles.cardLayer}>
          <OverlayCard scene={scene} localFrame={localFrame} />
        </div>
      ) : null}
      <Caption scene={scene} localFrame={localFrame} timeline={timeline} />
      <div style={styles.footer}>
        <span style={{color: accent}}>STYLE STUDY / FIRST 120</span>
        <span>{String(sceneIndex + 1).padStart(2, '0')} / {String(timeline.scenes.length).padStart(2, '0')}</span>
      </div>
      <div style={styles.progressTrack}>
        <i style={{width: `${Math.min(100, (seconds / timeline.targetDurationSeconds) * 100)}%`, background: accent}} />
      </div>
      <Audio src={staticFile('narration.wav')} volume={0.96} />
    </AbsoluteFill>
  );
};

const ChapterList: React.FC<{scene: Scene; localFrame: number}> = ({scene, localFrame}) => {
  const items = scene.visual.items ?? [];
  const color = accentColor(scene.chapter.accent);
  const progress = enter(localFrame, 20);
  return (
    <div style={{...styles.chapterList, opacity: progress, transform: `translateY(${(1 - progress) * 16}px)`}}>
      {items.map((item, index) => (
        <div key={item} style={styles.chapterListRow}>
          <span style={{...styles.chapterListIndex, color}}>{String(index + 1).padStart(2, '0')}</span>
          <span>{item}</span>
          <i style={{...styles.chapterListRule, background: index === 0 ? color : 'rgba(255,255,255,.18)'}} />
        </div>
      ))}
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  root: {color: palette.ink, fontFamily: 'Arial, Microsoft YaHei, sans-serif', overflow: 'hidden'},
  media: {position: 'absolute', width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'center'},
  glow: {position: 'absolute', inset: '-30%', filter: 'blur(100px)', opacity: 0.22, mixBlendMode: 'screen'},
  vignette: {position: 'absolute', inset: 0, background: 'radial-gradient(circle at 62% 44%, transparent 0%, rgba(1,6,10,.12) 44%, rgba(1,6,10,.72) 100%)'},
  chapter: {position: 'absolute', left: 58, top: 42, zIndex: 4, maxWidth: 720},
  eyebrow: {display: 'flex', alignItems: 'center', gap: 10, fontSize: 14, letterSpacing: 2.4, fontWeight: 800},
  eyebrowDot: {width: 8, height: 8, borderRadius: 999},
  chapterTitle: {marginTop: 8, fontSize: 29, lineHeight: 1.04, fontWeight: 900, letterSpacing: 0.2},
  cardLayer: {position: 'absolute', right: 58, top: 154, zIndex: 5, width: 420, display: 'flex', justifyContent: 'flex-end'},
  card: {minWidth: 350, padding: '18px 20px', border: '2px solid', background: 'rgba(5,12,18,.87)', boxShadow: '0 18px 44px rgba(0,0,0,.38)'},
  cardLabel: {fontSize: 13, letterSpacing: 2.1, fontWeight: 900},
  statValue: {marginTop: 8, fontSize: 68, lineHeight: 0.92, fontWeight: 900, letterSpacing: 0},
  statRule: {width: 78, height: 4, marginTop: 16},
  rows: {display: 'flex', flexDirection: 'column', gap: 8, marginTop: 14},
  row: {position: 'relative', display: 'flex', alignItems: 'center', gap: 10, minHeight: 34, padding: '0 10px', background: 'rgba(255,255,255,.07)', fontSize: 17, fontWeight: 800},
  rowIndex: {fontSize: 12, fontWeight: 900},
  rowBar: {height: 3, marginLeft: 'auto', opacity: 0.85},
  bars: {display: 'flex', flexDirection: 'column', gap: 12, marginTop: 16},
  barRow: {display: 'flex', alignItems: 'center', gap: 10},
  barKey: {width: 24, color: palette.muted, fontSize: 12, fontWeight: 900},
  barTrack: {flex: 1, height: 9, background: 'rgba(255,255,255,.12)'},
  barFill: {display: 'block', height: '100%'},
  barValue: {width: 48, textAlign: 'right', fontSize: 13},
  flow: {display: 'flex', alignItems: 'center', gap: 7, marginTop: 18},
  flowNode: {padding: '10px 8px', border: '1px solid', fontSize: 12, fontWeight: 900, letterSpacing: 0.6},
  flowArrow: {fontSize: 20, fontWeight: 900},
  caption: {position: 'absolute', left: 84, right: 84, bottom: 62, zIndex: 6, textAlign: 'center', textShadow: '0 3px 14px rgba(0,0,0,.82)', fontSize: 34, lineHeight: 1.18, fontWeight: 900},
  captionSmall: {display: 'block'},
  footer: {position: 'absolute', left: 58, right: 58, bottom: 21, zIndex: 6, display: 'flex', justifyContent: 'space-between', fontSize: 12, letterSpacing: 1.8, fontWeight: 800, color: palette.muted},
  progressTrack: {position: 'absolute', left: 58, right: 58, bottom: 11, zIndex: 6, height: 3, background: 'rgba(255,255,255,.2)'},
  gridPanel: {position: 'absolute', inset: 0, padding: '150px 88px 105px', background: '#070d12', zIndex: 1},
  gridMeta: {display: 'flex', justifyContent: 'space-between', color: palette.muted, fontSize: 14, letterSpacing: 2.2, fontWeight: 900},
  gridMetaRight: {color: palette.ink},
  grid: {display: 'grid', gridTemplateColumns: 'repeat(24, 1fr)', gridTemplateRows: 'repeat(10, 1fr)', gap: 5, height: '100%', marginTop: 24},
  cell: {display: 'block', minWidth: 0, minHeight: 0},
  chapterList: {position: 'absolute', left: 92, right: 92, top: 170, bottom: 150, zIndex: 2, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 17},
  chapterListRow: {display: 'flex', alignItems: 'center', gap: 18, color: palette.ink, fontSize: 25, fontWeight: 900},
  chapterListIndex: {width: 42, fontSize: 18},
  chapterListRule: {height: 4, width: 160, marginLeft: 'auto'},
};
