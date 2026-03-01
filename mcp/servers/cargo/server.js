/**
 * Rust Cargo MCP Server
 * 허용된 cargo 명령만 실행 가능한 안전한 MCP 서버
 */
const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
const { SSEServerTransport } = require('@modelcontextprotocol/sdk/server/sse.js');
const { z } = require('zod');
const http = require('http');
const { execSync } = require('child_process');

const WORKSPACE = process.env.WORKSPACE || '/workspace';
const MCP_PORT = parseInt(process.env.MCP_PORT || '3008');
const ALLOWED = (process.env.ALLOWED_COMMANDS || 'check,clippy,test,fmt,build,doc').split(',');
const DENIED = (process.env.DENIED_COMMANDS || 'install,uninstall,publish').split(',');

const server = new McpServer({
  name: 'cargo-runner',
  version: '1.0.0',
});

server.tool(
  'cargo_run',
  'Run a cargo command in the workspace',
  {
    command: z.enum(ALLOWED).describe('cargo subcommand to run'),
    args: z.string().optional().describe('additional arguments (e.g., "-- -D warnings")'),
    package: z.string().optional().describe('specific package in workspace (-p flag)'),
  },
  async ({ command, args, package: pkg }) => {
    if (DENIED.includes(command)) {
      return { content: [{ type: 'text', text: `Error: '${command}' is not allowed` }] };
    }

    const pkgFlag = pkg ? `-p ${pkg}` : '';
    const cmd = `cargo ${command} ${pkgFlag} ${args || ''}`;
    console.log(`Running: ${cmd}`);

    try {
      const output = execSync(cmd, {
        cwd: WORKSPACE,
        timeout: 120_000,
        encoding: 'utf8',
        env: { ...process.env, CARGO_TERM_COLOR: 'never' },
      });
      return { content: [{ type: 'text', text: `✅ Success\n${output}` }] };
    } catch (e) {
      return { content: [{ type: 'text', text: `❌ Failed\n${e.stderr || e.message}` }] };
    }
  }
);

server.tool(
  'cargo_check_all',
  'Run check + clippy + test in sequence (TDD verify step)',
  {},
  async () => {
    const commands = [
      'cargo check',
      'cargo clippy -- -D warnings',
      'cargo test',
    ];
    const results = [];
    for (const cmd of commands) {
      try {
        execSync(cmd, { cwd: WORKSPACE, timeout: 120_000, encoding: 'utf8',
          env: { ...process.env, CARGO_TERM_COLOR: 'never' } });
        results.push(`✅ ${cmd}`);
      } catch (e) {
        results.push(`❌ ${cmd}\n${e.stderr || e.message}`);
        break;  // 실패 시 중단
      }
    }
    return { content: [{ type: 'text', text: results.join('\n\n') }] };
  }
);

// HTTP 서버 (SSE transport)
const httpServer = http.createServer();
const transport = new SSEServerTransport('/sse', httpServer);
httpServer.get('/health', (_, res) => res.end('ok'));

httpServer.listen(MCP_PORT, () => {
  console.log(`Cargo MCP server running on port ${MCP_PORT}`);
  console.log(`Allowed: ${ALLOWED.join(', ')}`);
});

server.connect(transport);
