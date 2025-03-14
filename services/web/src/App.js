import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchItems = async () => {
      try {
        const response = await fetch('/api/items');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setItems(data);
        setLoading(false);
      } catch (error) {
        setError(error.message);
        setLoading(false);
      }
    };

    fetchItems();
  }, []);

  if (loading) return <div className="App">Loading...</div>;
  if (error) return <div className="App">Error: {error}</div>;

  return (
    <div className="App">
      <header className="App-header">
        <h1>Microservices Demo</h1>
        <p>Containerized Deployment Workflow for AWS</p>
      </header>
      <main>
        <h2>Items from API</h2>
        <ul className="items-list">
          {items.map(item => (
            <li key={item.id} className="item-card">
              <h3>{item.name}</h3>
              <p>{item.description}</p>
            </li>
          ))}
        </ul>
      </main>
      <footer>
        <p>&copy; 2023 Microservices Demo</p>
      </footer>
    </div>
  );
}

export default App;