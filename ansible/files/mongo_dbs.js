const express = require("express");
const app = express();
const port = process.env.HTTP_PORT;

app.get("/", async (req, res) => {
  const uri = process.env.MONGO_URI;
  const { MongoClient } = require("mongodb");
  const client = new MongoClient(uri);

  try {
      await client.connect();

      databasesList = await client.db().admin().listDatabases();
      res.write("Hello MongoDB server!\n");
      res.write("Databases:\n");
      databasesList.databases.forEach(db => res.write(` - ${db.name}\n`));

  } catch (e) {
      console.error(e);
  } finally {
      client.close();
  }

  res.write("Bye!");
  res.end();
});

app.get("/STOP", (req, res) => {
  res.write("Shutting down...");
  res.end();
  process.exit();
});

app.listen(port, function() {
  console.log(`Server listening on port ${port}`);
});

