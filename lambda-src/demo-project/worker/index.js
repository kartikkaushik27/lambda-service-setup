exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Hello from the self-service demo-project/worker lambda!",
      version: 1,
      input: event,
    }),
  };
};
