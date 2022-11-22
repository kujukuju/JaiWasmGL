class Renderer {
    static initialize() {
        

        window.addEventListener('resize', () => {
            Renderer.resize();
        });
    }

    static resize() {
        Renderer.application.renderer.resize(window.innerWidth, window.innerHeight);
        Jai.resize(window.innerWidth, window.innerHeight);
    }
}