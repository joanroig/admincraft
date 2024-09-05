require("dotenv").config(); // Load environment variables from .env file

const WebSocket = require("ws");
const { exec, spawn } = require("child_process");
const jwt = require("jsonwebtoken"); // For token-based authentication

const SECRET_KEY = process.env.SECRET_KEY; // Use the secret key from .env

if (!SECRET_KEY) {
  throw new Error("SECRET_KEY is not defined in .env file");
}

const wss = new WebSocket.Server({ port: 8080 });

console.log("WebSocket server is listening on port 8080");

function authenticate(token) {
  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    return decoded;
  } catch (e) {
    console.error("Authentication error:", e);
    return null;
  }
}

wss.on("connection", (ws, request) => {
  console.log("New client connected");

  const url = new URL(request.url, `ws://${request.headers.host}`);
  const token = url.searchParams.get("token");

  const user = authenticate(token);
  if (!user) {
    ws.close();
    return;
  }

  const logProcess = spawn("docker", ["logs", "-f", "minecraft"]);

  logProcess.stdout.on("data", (data) => {
    ws.send(data.toString());
  });

  logProcess.stderr.on("data", (data) => {
    ws.send(`Error: ${data.toString()}`);
  });

  logProcess.on("close", (code) => {
    console.log(`logProcess exited with code ${code}`);
  });

  ws.on("message", (message) => {
    const msgString = message.toString(); // Convert Buffer to string

    console.log(`Received message: ${msgString}`);

    if (msgString === "admincraft restart-server") {
      restartServer();
    } else {
      executeCommand(`docker exec minecraft send-command ${msgString}`);
    }
  });

  function restartServer() {
    console.log("Restarting the Minecraft server...");
    executeCommand("docker restart minecraft");
  }

  ws.on("close", () => {
    console.log("Client disconnected");
    logProcess.kill(); // Kill the log process when client disconnects
  });

  ws.on("error", (error) => {
    console.error("WebSocket error:", error);
  });

  ws.send(`${user.userId} connected`);
});

function executeCommand(command) {
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return;
    }
    if (stderr) {
      console.error(`stderr: ${stderr}`);
      return;
    }

    console.log(`stdout: ${stdout}`);
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(stdout);
      }
    });
  });
}
