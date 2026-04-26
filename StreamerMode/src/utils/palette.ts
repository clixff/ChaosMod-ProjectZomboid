import colors from "colors";

export const palette = {
  purple: (s: string) => colors.brightBlue(s),
  orange: (s: string) => colors.brightYellow(s),
  green: (s: string) => colors.green(s),
  red: (s: string) => colors.red(s),
  gray: (s: string) => colors.gray(s),
  white: (s: string) => colors.white(s),
  bold: (s: string) => colors.bold(s),
};
