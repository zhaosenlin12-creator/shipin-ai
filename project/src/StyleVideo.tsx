import React from 'react';
import { AbsoluteFill, interpolate, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { Audio, Video } from '@remotion/media';

type Scene = {
  id: string;
  start: number;
  duration: number;
  presenter: { sourceStart: number; mode: string };
  caption: { zh: string; en: string };
  component: { type: string; label: string; value: string };
};

type Timeline = {
  fps: number;
  width: number;
  height: number;
  targetDurationSeconds: number;
  scenes: Scene[];
};

type Props = { timeline: Timeline };

const colors = {
  paper: '#091016',
  ink: '#f4f7fa',
  muted: '#aeb8c2',
  blue: '#56a8ff',
  red: '#ff5666',
  green: '#62e8a1',
  yellow: '#f2db65',
};

const sceneAt = (scenes: Scene[], seconds: number) => scenes.find((scene) => seconds >= scene.start && seconds < scene.start + scene.duration) ?? scenes.at(-1)!;

const fadeIn = (frame: number, fps: number) => interpolate(frame, [0, 10], [0, 1], { extrapolateRight: 'clamp' });

const ComponentCard: React.FC<{ scene: Scene; localFrame: number; fps: number }> = ({ scene, localFrame, fps }) => {
  const progress = interpolate(localFrame, [0, 18], [0, 1], { extrapolateRight: 'clamp' });
  const type = scene.component.type;
  const accent = type === 'warning' || type === 'comparison' ? colors.red : type === 'close' ? colors.yellow : colors.green;
  if (type === 'metric' || type === 'hook' || type === 'quote' || type === 'close') {
    return <div style={{ ...styles.card, borderColor: accent, width: 560, transform: `translateX(${(1 - progress) * 32}px)` }}>
      <div style={{ ...styles.kicker, color: accent }}>{scene.component.label}</div>
      <div style={styles.value}>{scene.component.value}</div>
      <div style={styles.cardLine}>{type === 'close' ? 'ONE LOOP COMPOUNDS' : 'BUILD A POSITION'}</div>
    </div>;
  }
  if (type === 'chart' || type === 'comparison') {
    return <div style={{ ...styles.card, borderColor: accent, width: 570 }}>
      <div style={{ ...styles.kicker, color: accent }}>{scene.component.label}</div>
      <div style={styles.bars}>
        <div style={{ ...styles.bar, width: `${44 + progress * 28}%`, background: colors.red }}><span>TOOL USE</span><b>{type === 'comparison' ? 'MORE' : '44%'}</b></div>
        <div style={{ ...styles.bar, width: `${24 + progress * 52}%`, background: colors.green }}><span>LEVERAGE</span><b>{type === 'comparison' ? 'VALUE' : '76%'}</b></div>
      </div>
    </div>;
  }
  if (type === 'stack' || type === 'flow' || type === 'list') {
    const rows = type === 'stack' ? ['JUDGMENT', 'WORKFLOW', 'REUSABLE ASSET'] : type === 'flow' ? ['COPY', 'ASSET', 'EDIT', 'PUBLISH'] : ['FRAGMENTED TIME', 'REPEATED WORK', 'NO MEMORY'];
    return <div style={{ ...styles.card, borderColor: type === 'list' ? colors.blue : colors.green, width: 585 }}>
      <div style={{ ...styles.kicker, color: type === 'list' ? colors.blue : colors.green }}>{scene.component.label}</div>
      <div style={styles.rows}>{rows.map((row, index) => <div key={row} style={{ ...styles.row, opacity: interpolate(localFrame, [index * 6, index * 6 + 9], [0.25, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }) }}><span style={{ color: type === 'list' ? colors.red : colors.green }}>{String(index + 1).padStart(2, '0')}</span>{row}<i style={{ width: `${40 + index * 16}%`, background: type === 'list' ? colors.blue : colors.green }} /></div>)}</div>
    </div>;
  }
  return <div style={{ ...styles.card, borderColor: colors.red, width: 560 }}><div style={{ ...styles.kicker, color: colors.red }}>{scene.component.label}</div><div style={styles.cardLine}>{scene.component.value === '?' ? 'DIRECTION > SPEED' : 'PROMPTS ≠ LEVERAGE'}</div></div>;
};

export const StyleVideo: React.FC<Props> = ({ timeline }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const seconds = frame / fps;
  const scene = sceneAt(timeline.scenes, seconds);
  const localFrame = Math.max(0, frame - scene.start * fps);
  const cleanSceneIndex = timeline.scenes.findIndex((item) => item.id === scene.id);
  const sourceStart = scene.presenter.sourceStart;
    const sceneStartFrame = Math.round(sourceStart * 60);
  const zoom = interpolate(localFrame, [0, scene.duration * fps], [1.03, 1.08], { extrapolateRight: 'clamp' });
  const xDrift = Math.sin(frame / 92) * 12;
  return <AbsoluteFill style={styles.root}>
    <Audio src={staticFile('narration.wav')} volume={0.92} />
    <AbsoluteFill style={{ background: colors.paper }} />
    <Video src={staticFile('avatar-master.mp4')} trimBefore={sceneStartFrame} loop muted volume={0} objectFit="cover" style={{ ...styles.presenter, transform: `scale(${zoom}) translateX(${xDrift}px)` }} />
    <AbsoluteFill style={styles.tint} />
    <div style={{ ...styles.topLabel, opacity: fadeIn(localFrame, fps) }}><span style={{ color: cleanSceneIndex % 3 === 0 ? colors.blue : cleanSceneIndex % 3 === 1 ? colors.red : colors.green }}>[ AI POSITION ]</span><small>STYLE DISTILLATION / 2026</small></div>
    <div style={{ ...styles.sceneIndex, opacity: fadeIn(localFrame, fps) }}>{String(cleanSceneIndex + 1).padStart(2, '0')}<span>/ {String(timeline.scenes.length).padStart(2, '0')}</span></div>
    <div style={styles.cardLayer}><ComponentCard scene={scene} localFrame={localFrame} fps={fps} /></div>
    <div style={{ ...styles.caption, opacity: fadeIn(localFrame, fps) }}><div>{scene.caption.zh}</div><small>{scene.caption.en}</small></div>
    <div style={styles.progress}><i style={{ width: `${(seconds / timeline.targetDurationSeconds) * 100}%` }} /></div>
  </AbsoluteFill>;
};

const styles: Record<string, React.CSSProperties> = {
  root: { color: colors.ink, fontFamily: 'Arial, Microsoft YaHei, sans-serif', overflow: 'hidden' },
  presenter: { position: 'absolute', width: '100%', height: '100%', objectPosition: '50% 48%' },
  tint: { background: 'linear-gradient(180deg, rgba(5,10,15,.18) 18%, rgba(5,10,15,.53) 70%, rgba(5,10,15,.82) 100%)' },
  topLabel: { position: 'absolute', left: 72, right: 72, top: 96, display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', fontWeight: 800, letterSpacing: 2, fontSize: 28 },
  sceneIndex: { position: 'absolute', right: 72, top: 158, color: colors.ink, fontSize: 60, fontWeight: 900 },
  cardLayer: { position: 'absolute', left: 72, right: 72, top: 255, display: 'flex', justifyContent: 'flex-start' },
  card: { padding: '20px 24px', background: 'rgba(7,14,21,.84)', border: '3px solid', borderRadius: 5, boxShadow: '0 18px 50px rgba(0,0,0,.24)' },
  kicker: { fontSize: 19, letterSpacing: 2, fontWeight: 900 },
  value: { marginTop: 10, color: colors.ink, fontSize: 70, lineHeight: .95, fontWeight: 900 },
  cardLine: { marginTop: 10, color: colors.ink, fontSize: 21, lineHeight: 1.25, fontWeight: 800 },
  bars: { display: 'flex', flexDirection: 'column', gap: 11, marginTop: 14 },
  bar: { minWidth: 260, height: 46, padding: '0 13px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#091016', fontSize: 17, fontWeight: 900 },
  rows: { display: 'flex', flexDirection: 'column', gap: 8, marginTop: 12 },
  row: { position: 'relative', display: 'flex', alignItems: 'center', gap: 12, padding: '8px 10px', background: 'rgba(255,255,255,.08)', fontSize: 20, fontWeight: 800 },
  caption: { position: 'absolute', left: 72, right: 72, bottom: 208, textAlign: 'center', textShadow: '0 4px 10px rgba(0,0,0,.8)', fontWeight: 900, fontSize: 45, lineHeight: 1.22 },
  progress: { position: 'absolute', left: 72, right: 72, bottom: 126, height: 6, background: 'rgba(255,255,255,.25)' },
};
