// Workspace: First Workspace
#import "Default_Metaprogram";

PLUGIN_INIT_STRING :: #string DONE
        Plugin_0 :: #import "precursory";
        p_0: *Metaprogram_Plugin = Plugin_0.get_plugin();
        p_0.workspace = w;
        array_add(results, p_0);
        Plugin_1 :: #import "Check";
        p_1: *Metaprogram_Plugin = Plugin_1.get_plugin();
        p_1.workspace = w;
        array_add(results, p_1);

DONE

//
// #insert text. Generated from C:/jai/modules/Metaprogram_Plugins.jai:86.
//
        Plugin_0 :: #import "precursory";
        p_0: *Metaprogram_Plugin = Plugin_0.get_plugin();
        p_0.workspace = w;
        array_add(results, p_0);
        Plugin_1 :: #import "Check";
        p_1: *Metaprogram_Plugin = Plugin_1.get_plugin();
        p_1.workspace = w;
        array_add(results, p_1);

