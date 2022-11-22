class Renderer {
    static initialize() {


        window.addEventListener('resize', () => {
            Renderer.resize();
        });
    }

    static resize() {
        Jai.resize(window.innerWidth, window.innerHeight);
    }
}