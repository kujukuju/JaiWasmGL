class Loop {
    // static PRECHECK = 4;
    // static DELAY = 16;

    // static loopTime = 0;

    // TODO precheck should be based on how the vsync divides into 60 fps
    // TODO needs to be better than this
    // TODO maybe rather than precheck, just have the lowest milliseconds that it divides, and if the remaining time is less than that

    static initialize() {
        // Loop.loopTime = Date.now();
        Loop.loop();
    }

    static loop() {
        Jai.update();

        // if (start - Loop.loopTime >= Loop.DELAY - Loop.PRECHECK) {
        //     while (start - Loop.loopTime < Loop.DELAY) {
        //         start = Date.now();
        //     }

        //     Renderer.cpuTracker.beginFrame(start);

        //     Logic.update();
        //     Renderer.render(start);

        //     const finish = Date.now();
        //     Loop.loopTime = start;
        //     Renderer.cpuTracker.endFrame(finish);
        // }

        window.requestAnimationFrame(Loop.loop);
    }
}