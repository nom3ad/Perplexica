import { startWebSocketServer } from './websocket';
import express from 'express';
import cors from 'cors';
import http from 'http';
import routes from './routes';
import { getPort } from './config';
import logger from './utils/logger';
import path from 'path';

// Make sure commands gracefully respect termination signals (e.g. from Docker)
process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));

const port = getPort();

const app = express();
const server = http.createServer(app);

const corsOptions = {
  origin: '*',
};

app.use(cors(corsOptions));
app.use(express.json());

app.use('/api', routes);
app.get('/api', (_, res) => {
  res.status(200).json({ status: 'ok' });
});

server.listen(port, () => {
  logger.info(`Server is running on port ${port}`);
});

startWebSocketServer(server);

process.on('uncaughtException', (err, origin) => {
  logger.error(`Uncaught Exception at ${origin}: ${err}`);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error(`Unhandled Rejection at: ${promise}, reason: ${reason}`);
});


if (process.env.NODE_ENV === 'production') {
  const baseDir = process.cwd();
  const uiDir = path.join(baseDir, 'ui', '.next', 'standalone')
  process.chdir(uiDir);
  const NextServer = require(path.relative(__dirname, uiDir) + '/node_modules/next/dist/server/next-server').default;
  const fs = require('fs');
  const { config } = JSON.parse(fs.readFileSync(path.join(uiDir, '.next', 'required-server-files.json')));

  logger.info('Starting Next.js server');
  const nextServer = new NextServer({
    port,
    dir: uiDir,
    customServer: true,
    dev: false,
    conf: config,
  });
  app.all('*', nextServer.getRequestHandler());
}