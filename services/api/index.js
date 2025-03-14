const express = require('express');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('API Service is healthy');
});

// Sample API endpoints
app.get('/api/items', (req, res) => {
  const items = [
    { id: 1, name: 'Item 1', description: 'Description for Item 1' },
    { id: 2, name: 'Item 2', description: 'Description for Item 2' },
    { id: 3, name: 'Item 3', description: 'Description for Item 3' }
  ];
  res.json(items);
});

app.get('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  // In a real app, you would fetch from a database
  const item = { id, name: `Item ${id}`, description: `Description for Item ${id}` };
  res.json(item);
});

// Start the server
app.listen(port, () => {
  console.log(`API service listening at http://localhost:${port}`);
});