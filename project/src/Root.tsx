import React from 'react';
import { Composition } from 'remotion';
import { SourceStyleVideo, type Timeline } from './SourceStyleVideo';
import timeline from '../timeline/source-style-first120.json';

const sourceStyleTimeline = timeline as unknown as Timeline;

export const RemotionRoot: React.FC = () => (
  <Composition
    id="SourceStyleFirst120"
    component={SourceStyleVideo}
    durationInFrames={sourceStyleTimeline.targetDurationSeconds * sourceStyleTimeline.fps}
    fps={sourceStyleTimeline.fps}
    width={sourceStyleTimeline.width}
    height={sourceStyleTimeline.height}
    defaultProps={{ timeline: sourceStyleTimeline }}
  />
);
