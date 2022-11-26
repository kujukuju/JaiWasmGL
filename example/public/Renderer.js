class Renderer {
    static initialize() {
        window.addEventListener('resize', () => {
            Renderer.resize();
        });

        Renderer.resize();
    }

    static resize() {
        Jai.resize(window.innerWidth, window.innerHeight);
        document.getElementById('canvas').width = window.innerWidth;
        document.getElementById('canvas').height = window.innerHeight;
    }
}