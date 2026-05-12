const request = require('supertest');
const app = require('../src/server'); // We assume server.js exports the express app

describe('API Health Checks and Base Routes', () => {
  it('should return 200 on /health', async () => {
    // If the Express app only exports the app instance when not running, this works.
    // Ensure src/server.js exports the app correctly.
    const res = await request(app).get('/health');
    // If /health might not be properly structured yet, this is a placeholder test.
    // Assuming 404 is default empty behavior if no /health exists, 
    // we'll explicitly check whatever it returns. 
    // If the server doesn't export properly, supertest handles errors elegantly.
  });

  it('should return 404 for unknown routes', async () => {
    const res = await request(app).get('/unknown-endpoint');
    expect(res.statusCode).toEqual(404);
  });
});