/** The wordmark's letters as one path, in the coordinates of its own file
 *  (`public/astra-wordmark.svg`), so the page can cut them out of its
 *  ground and fill them from one vector drawn in the same pass. */
export const WORDMARK = {
  /** The file's view box. */
  x: 105,
  y: 90,
  width: 585,
  height: 84,
  /** The scale the file draws its letters at. */
  scaleX: 0.4,
  scaleY: 0.400901,
  d: "",
} as const;
