class Loop {
    static loop() {
        Jai.update();

        window.requestAnimationFrame(Loop.loop);
    }
}