require("init")(process.argv, global.paths, initLogging)
    .then(() => {
                require("plutonium-backend").init();

    });
