class Renderer {
    static initialize() {
        window.addEventListener('resize', () => {
            Renderer.resize();
        });
        
        document.getElementById('canvas').width = window.innerWidth;
        document.getElementById('canvas').height = window.innerHeight;
    }

    static resize() {
        Jai.resize(window.innerWidth, window.innerHeight);
        document.getElementById('canvas').width = window.innerWidth;
        document.getElementById('canvas').height = window.innerHeight;
    }
}