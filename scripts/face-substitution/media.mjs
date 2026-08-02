export const makeFrameTimes = (durationSeconds, count) =>
  Array.from(
    {length: count},
    (_, index) => Number((((index + 0.5) * durationSeconds) / count).toFixed(3)),
  );

export const assertComparableMedia = (source, output) => {
  if (source.width !== output.width || source.height !== output.height || !output.hasAudio) {
    throw new Error('Output must preserve source dimensions and AAC audio');
  }
};
