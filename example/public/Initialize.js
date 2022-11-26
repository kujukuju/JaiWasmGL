window.addEventListener('load', () => {
    Jai.initialize(document.getElementById('canvas'), '/main32.wasm');
});

const initialized = () => {
    Renderer.initialize();
    Loop.loop();
};

