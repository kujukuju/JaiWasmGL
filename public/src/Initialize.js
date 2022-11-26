window.addEventListener('load', () => {
    Jai.initialize(document.getElementById('canvas'));
});

const initialized = () => {
    Renderer.initialize();
    Loop.loop();
};

