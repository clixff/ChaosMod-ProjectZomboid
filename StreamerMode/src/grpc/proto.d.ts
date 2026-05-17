// Ambient declaration for `import x from "...proto" with { type: "text" }`
// imports. Bun's bundler embeds the file contents as a string in
// `bun build --compile` mode, but TypeScript needs to be told the import
// resolves to a string.
declare module "*.proto" {
  const content: string;
  export default content;
}
