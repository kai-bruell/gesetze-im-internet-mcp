import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath } from 'url';
import { z } from 'zod';

const execAsync = promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TOOLS_PATH = path.join(__dirname, '../tools');
const LAWS_DIR = process.env.LAWS_DIR || '/app/laws';

// Input sanitization
function sanitizeLawName(name) {
  if (!/^[a-zA-Z0-9_]+$/.test(name)) {
    throw new Error(`Invalid law name: "${name}". Only alphanumeric and underscore allowed.`);
  }
  return name;
}

function sanitizeParagraph(para) {
  if (!/^[§\s\w]+$/.test(para)) {
    throw new Error(`Invalid paragraph: "${para}"`);
  }
  return para;
}

function sanitizeAbsatz(absatz) {
  if (!absatz) return null;
  if (!/^(\d+|\[\d+(,\d+)*\])$/.test(absatz)) {
    throw new Error(`Invalid absatz: "${absatz}". Use number or [1,2,3] format.`);
  }
  return absatz;
}

async function runScript(scriptName, args) {
  const scriptPath = path.join(TOOLS_PATH, scriptName);
  const cmd = `"${scriptPath}" ${args.join(' ')}`;

  const { stdout, stderr } = await execAsync(cmd, {
    cwd: '/app',
    timeout: 30000,
    encoding: 'utf8',
    env: { ...process.env, LAWS_DIR },
  });

  if (stderr && !stdout) {
    throw new Error(stderr);
  }

  return stdout || stderr;
}

const server = new McpServer({
  name: 'german-law-server',
  version: '2.0.0',
});

server.tool(
  'download_law',
  'Download a German law XML file from gesetze-im-internet.de',
  {
    law_name: z.string().describe('Name of the law (e.g., "estg", "ao_1977", "bgb")'),
    force_update: z.boolean().optional().describe('Force update even if file exists'),
  },
  async ({ law_name, force_update }) => {
    const safeName = sanitizeLawName(law_name);
    const args = force_update ? ['--force-update', safeName] : [safeName];

    const result = await runScript('law-xml-downloader.sh', args);
    return { content: [{ type: 'text', text: result }] };
  }
);

server.tool(
  'get_paragraph',
  'Extract specific paragraph(s) from a German law',
  {
    paragraph: z.string().describe('Paragraph identifier (e.g., "§ 1", "§ 70")'),
    law_name: z.string().describe('Name of the law (e.g., "estg", "ao_1977")'),
    absatz: z.string().optional().describe('Optional: specific subsection number or list [1,3,5]'),
  },
  async ({ paragraph, law_name, absatz }) => {
    const safePara = sanitizeParagraph(paragraph);
    const safeName = sanitizeLawName(law_name);
    const safeAbsatz = sanitizeAbsatz(absatz);

    const args = [`"${safePara}"`, safeName];
    if (safeAbsatz) {
      args.push(`"${safeAbsatz}"`);
    }

    const result = await runScript('get-para.sh', args);
    return { content: [{ type: 'text', text: result }] };
  }
);

server.tool(
  'list_contents',
  'List all paragraphs in a German law (table of contents)',
  {
    law_name: z.string().describe('Name of the law (e.g., "estg", "ao_1977")'),
  },
  async ({ law_name }) => {
    const safeName = sanitizeLawName(law_name);

    const result = await runScript('table-of-contents.sh', [safeName]);
    return { content: [{ type: 'text', text: result }] };
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('German Law MCP server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
