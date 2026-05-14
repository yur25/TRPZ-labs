const request = require('supertest');

// Mock the DB to avoid needing a real database connection during tests
jest.mock('../src/db', () => ({
  query: jest.fn()
}));

const db = require('../src/db');
const app = require('../src/server');

describe('API Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Base Routes & Health Checks', () => {
    it('should return 406 on / if html is not accepted', async () => {
      const res = await request(app)
        .get('/')
        .set('Accept', 'application/json');
      expect(res.statusCode).toEqual(406);
    });

    it('should return 200 on / for valid html requests', async () => {
      const res = await request(app)
        .get('/')
        .set('Accept', 'text/html');
      expect(res.statusCode).toEqual(200);
      expect(res.text).toContain('Simple Inventory API');
    });

    it('should return 200 on /health/alive', async () => {
      const res = await request(app).get('/health/alive');
      expect(res.statusCode).toEqual(200);
      expect(res.text).toContain('OK');
    });

    it('should return 200 on /health/ready if DB is ok', async () => {
      db.query.mockResolvedValueOnce([]); // Mock successful query wrapper
      const res = await request(app).get('/health/ready');
      expect(res.statusCode).toEqual(200);
    });

    it('should return 500 on /health/ready if DB fails', async () => {
      db.query.mockRejectedValueOnce(new Error('Connection failed'));
      const res = await request(app).get('/health/ready');
      expect(res.statusCode).toEqual(500);
      expect(res.text).toContain('Database error: Connection failed');
    });

    it('should return 404 for unknown routes', async () => {
      const res = await request(app).get('/unknown-endpoint');
      expect(res.statusCode).toEqual(404);
    });
  });

  describe('Inventory Endpoints /items', () => {
    it('should list items in JSON format', async () => {
      db.query.mockResolvedValueOnce([ [{ id: 1, name: 'Item 1' }] ]);
      const res = await request(app)
        .get('/items')
        .set('Accept', 'application/json');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual([{ id: 1, name: 'Item 1' }]);
    });

    it('should create an item and return JSON', async () => {
      db.query.mockResolvedValueOnce([{ insertId: 10 }]);
      const res = await request(app)
        .post('/items')
        .set('Accept', 'application/json')
        .send({ name: 'New Item', quantity: 5 });
      
      expect(res.statusCode).toEqual(201);
      expect(res.body).toEqual({ id: 10, name: 'New Item', quantity: 5 });
      expect(db.query).toHaveBeenCalledTimes(1);
    });

    it('should fail to create item if fields are missing', async () => {
      const res = await request(app).post('/items').send({ quantity: 5 });
      expect(res.statusCode).toEqual(400);
    });

    it('should get item details by id', async () => {
      db.query.mockResolvedValueOnce([
        [{ id: 1, name: 'Item 1', quantity: 10, created_at: '2026' }]
      ]);
      const res = await request(app)
        .get('/items/1')
        .set('Accept', 'application/json');
        
      expect(res.statusCode).toEqual(200);
      expect(res.body.id).toEqual(1);
    });
    
    it('should return 404 if item details not found', async () => {
      db.query.mockResolvedValueOnce([[]]);
      const res = await request(app).get('/items/99');
      expect(res.statusCode).toEqual(404);
    });
  });
});
