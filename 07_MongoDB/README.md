# 🧱 MongoDB Practice: Building a Product Catalog Database
MongoDB is a modern, document-oriented NoSQL database designed for flexibility and scalability.
Unlike traditional relational databases that store data in tables and rows, MongoDB stores information in JSON-like documents — making it easier to handle unstructured or evolving data.

![MongoDB Logo](https://upload.wikimedia.org/wikipedia/en/4/45/MongoDB-Logo.svg](https://studio3t.com/wp-content/uploads/2020/09/introduction-to-mongodb.png)


## 📘 Table of Contents

* [1. Introduction](#1-introduction)
  * [Learning Objectives](#learning-objectives)
* [2. Session Agenda (90 Minutes)](#2-session-agenda-90-minutes)
* [3. Environment Setup](#3-environment-setup)
* [4. MongoDB + Mongo Express: Core Concepts](#4-mongodb--mongo-express-core-concepts)
* [5. Task 1: Load and Explore Product Data](#5-task-1-load-and-explore-product-data)
* [6. Task 2: Querying and Filtering Products](#6-task-2-querying-and-filtering-products)
* [7. Task 3: Updating and Aggregating Data](#7-task-3-updating-and-aggregating-data)
* [8. Challenge Tasks: Real-world Scenarios](#8-challenge-tasks-real-world-scenarios)
* [9. Troubleshooting & Tips](#9-troubleshooting--tips)
* [10. Key Takeaways](#10-key-takeaways)

---

## 1. Introduction

In this session, you’ll set up a **MongoDB environment** using Docker and work with a simple **product catalog database**. You’ll learn to insert, query, and update documents — building practical experience for real-world data management.

### 🎯 Learning Objectives

By the end of this session, you will:

1. Run MongoDB and Mongo Express via Docker Compose.
2. Insert and explore JSON data into MongoDB.
3. Perform CRUD (Create, Read, Update, Delete) operations.
4. Use aggregation and filtering for insights.
5. Understand document structure and schema flexibility.

---

## 2. Session Agenda (90 Minutes)

| Duration | Topic                                  | Goal                                      |
| -------- | -------------------------------------- | ----------------------------------------- |
| 10 min   | Introduction & Setup                   | Run MongoDB and UI                        |
| 15 min   | Load Sample Data                       | Insert product JSON                       |
| 20 min   | Querying Data                          | Use filters, projections, and conditions  |
| 20 min   | Updating & Aggregating                 | Learn updates and analysis queries        |
| 15 min   | Challenge Tasks                        | Apply knowledge in realistic scenarios    |
| 10 min   | Wrap-up & Discussion                   | Review key learnings                      |

---

## 3. Environment Setup

### Step 3.1: Project Structure

```
07_MongoDB/
├── compose.yml
├── sample_data/
│   └── products.json
└── README.md
```

### Step 3.2: Docker Compose File

```yaml
version: "3.9"

services:
  mongodb:
    image: mongo:6.0
    container_name: mongodb
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
      - ./sample_data:/sample_data

  mongo-express:
    image: mongo-express
    container_name: mongo-express
    restart: always
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_SERVER: mongodb
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: password
      ME_CONFIG_MONGODB_AUTH_DATABASE: admin
    depends_on:
      - mongodb

volumes:
  mongodb_data:
```

**Run the setup:**

```bash
docker compose up -d
```

✅ Access the tools:

- **Mongo Express UI:** http://localhost:8081  
User: admin
Password: pass
- **MongoDB Shell (CLI):**

  ```bash
  docker exec -it mongodb mongosh -u admin -p password --authenticationDatabase admin
  ```

---

## 4. MongoDB + Mongo Express: Core Concepts

| Concept          | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| **Database**     | A logical grouping of collections.                                          |
| **Collection**   | A group of JSON-like documents (similar to a table in SQL).                 |
| **Document**     | A record stored in BSON (Binary JSON) format.                              |
| **CRUD**         | Basic operations: Create, Read, Update, Delete.                             |
| **Aggregation**  | Powerful way to process and analyze data via pipeline stages.               |
| **Schema-less**  | Documents can have flexible fields — great for semi-structured data.        |

---

## 5. Task 1: Load and Explore Product Data

### Step 5.1: Sample Data

`sample_data/products.json`

```json
[
  {
    "product_id": 1,
    "name": "Running Shoes",
    "category": "Footwear",
    "price": 89.99,
    "attributes": {
      "size": 42,
      "weight": "0.9kg",
      "color": "black"
    }
  },
  {
    "product_id": 2,
    "name": "Laptop",
    "category": "Electronics",
    "price": 1200.0,
    "attributes": {
      "processor": "Intel i7",
      "ram": "16GB",
      "storage": "512GB SSD"
    }
  },
  {
    "product_id": 3,
    "name": "Photo Editor Pro",
    "category": "Software",
    "price": 59.99,
    "attributes": {
      "subscription_period": "12 months",
      "platform": ["Windows", "macOS"]
    }
  }
]
```

### Step 5.2: Load Data into MongoDB

```bash
docker exec -it mongodb mongoimport   --username admin   --password password   --authenticationDatabase admin   --db shop   --collection products   --file /sample_data/products.json   --jsonArray
```

### Step 5.3: Verify Data

```bash
docker exec -it mongodb mongosh -u admin -p pass --authenticationDatabase admin

use shop
db.products.find().pretty()
```

---

## 6. Task 2: Querying and Filtering Products

### Basic Queries

```js
use shop

// Show all products
db.products.find()

// Show products in category 'Electronics'
db.products.find({ category: "Electronics" })

// Only show name and price fields
db.products.find({}, { name: 1, price: 1 })

// Filter products under 100 EUR
db.products.find({ price: { $lt: 100 } })
```

### Fun Practice Ideas 💡

1. Find all products that are **not software**.
2. List all **products with color black**.
3. Find all products with **RAM attribute** (hint: use `$exists`).

---

## 7. Task 3: Updating and Aggregating Data

### Updates

```js
use shop

// Add a new field: stock count
db.products.updateMany({}, { $set: { stock: 50 } })

// Update one product's price
db.products.updateOne({ name: "Running Shoes" }, { $set: { price: 79.99 } })

// Rename a field
db.products.updateMany({}, { $rename: { "attributes.weight": "attributes.item_weight" } })
```

### Deletions

```js
// Remove one product
db.products.deleteOne({ name: "Photo Editor Pro" })

// Remove all software products
db.products.deleteMany({ category: "Software" })
```

### Aggregations

```js
// Average price by category
db.products.aggregate([
  { $group: { _id: "$category", avgPrice: { $avg: "$price" } } }
])

// Count total products by category
db.products.aggregate([
  { $group: { _id: "$category", count: { $sum: 1 } } }
])
```

---


## 8. Challenge Tasks: Real-world Scenarios

🎯 **Challenge 1: Discount Campaign**
> Add a `discounted_price` field that applies a 10% discount to products over €100.

💡 *Hint:* Use `$mul` and `$set` operators inside `updateMany()`.

<details>
<summary>💡 Show Solution</summary>

```javascript
use shop

db.products.updateMany(
  { price: { $gt: 100 } },
  [
    { 
      $set: { 
        discounted_price: { 
          $multiply: [ "$price", 0.9 ] 
        } 
      } 
    }
  ]
)
```
</details>

---

🎯 **Challenge 2: Stock Management**
> Decrease stock by 1 when a product is sold.

💡 *Hint:* Use `$inc: { stock: -1 }`.

<details>
<summary>💡 Show Solution</summary>

```javascript
use shop

// Initialize stock for demo
db.products.updateMany({}, { $set: { stock: 10 } })

// Simulate a sale
db.products.updateOne(
  { name: "Laptop" },
  { $inc: { stock: -1 } }
)
```
</details>

---

🎯 **Challenge 3: Product Search**
> Find all products where the name includes the word *“Pro”* (case-insensitive).

💡 *Hint:* Use regex — `{ name: { $regex: /pro/i } }`.

<details>
<summary>💡 Show Solution</summary>

```javascript
use shop

db.products.find(
  { name: { $regex: /pro/i } },
  { name: 1, category: 1, price: 1, _id: 0 }
)
```
</details>

---

## 9. Troubleshooting & Tips

| Issue | Cause | Fix |
|-------|--------|------|
| `Unauthorized: command requires authentication` | MongoDB started without correct env vars | Ensure `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` match |
| Mongo Express “connection failed” | Wrong credentials or service name | Check `ME_CONFIG_MONGODB_SERVER` = `mongodb` |
| Import fails | Wrong path | Confirm `/sample_data/products.json` exists inside container |
| JSON import invalid | Missing `--jsonArray` flag | Always include it when importing an array |

---

## 10. Key Takeaways

✅ **You have learned to:**

* Run MongoDB + Mongo Express in Docker.
* Insert JSON data directly into a collection.
* Perform CRUD operations from CLI or Mongo Express UI.
* Use aggregation pipelines to analyze data.
* Handle updates and dynamic document structures.

**Next Steps:**
- Explore **indexing and performance tuning**.
- Try **nested document queries** and **lookups** (`$lookup`).
- Extend this project with a **“Customers + Orders”** dataset.

---

**Outcome:** You now have a working MongoDB lab setup — perfect for exploring data modeling, document queries, and real-world database tasks in a hands-on, fun way 🚀
