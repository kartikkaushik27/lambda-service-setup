exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Hello from the self-service demo-project/scheduler lambda! (v2-native-owned)",
      input: event,
    }),
  };
};
