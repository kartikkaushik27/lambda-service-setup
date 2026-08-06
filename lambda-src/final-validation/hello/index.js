exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Hello from final-validation/hello (v2-selective-test)",
      input: event,
    }),
  };
};
