window.addEventListener('load', () => {
    Jai.initialize(document.getElementById('canvas'), '/main32.wasm', exported);
});

const exported = {
    simple_function: () => {
        console.log('Called simple function.');
    },
};

const initialized = () => {
    Renderer.initialize();
    Loop.loop();
};
