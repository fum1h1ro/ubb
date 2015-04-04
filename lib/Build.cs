﻿using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;

public class Build {
  enum Target {
    Unknown,
    Development,
    Release,
    Final,
  }
  private static string _bakDefines;
  private static string _buildPath = "<%= output %>";
  // Android
  static void PerformBuild() {
    Debug.Log("build start");
    string[] scenes = GetAllScenes();
    update_symbols();
    string error = BuildPipeline.BuildPlayer(scenes, "build.apk",  BuildTarget.Android, BuildOptions.None);
    if (string.IsNullOrEmpty(error)) {
      Debug.Log("build end");
      EditorApplication.Exit(0);
    } else {
      // build failed
      Debug.Log(error);
      EditorApplication.Exit(1);
    }
  }
  // iOS
  public static void PerformiOSBuild() {
    Debug.Log("build start");
    string[] scenes = GetAllScenes();
    BuildOptions opt = BuildOptions.SymlinkLibraries;
    Target tgt = (UnityEditorInternal.InternalEditorUtility.inBatchMode) ? get_target() : Target.Development;
    if (tgt == Target.Unknown) {
      Debug.LogError("TARGET UNKNOWN");
      EditorApplication.Exit(1);
    }
    switch (tgt) {
    case Target.Development:
      opt |= BuildOptions.Development;
      PlayerSettings.strippingLevel = StrippingLevel.Disabled;
      PlayerSettings.iOS.scriptCallOptimization = ScriptCallOptimizationLevel.SlowAndSafe;
      break;
    case Target.Release:
      //opt |= BuildOptions.Development;
      //PlayerSettings.strippingLevel = StrippingLevel.StripByteCode; // リフレクション使ってる箇所で死ぬ
      PlayerSettings.strippingLevel = StrippingLevel.Disabled;
      PlayerSettings.iOS.scriptCallOptimization = ScriptCallOptimizationLevel.FastButNoExceptions;
      break;
    case Target.Final:
      //PlayerSettings.strippingLevel = StrippingLevel.StripByteCode;
      PlayerSettings.strippingLevel = StrippingLevel.Disabled;
      PlayerSettings.iOS.scriptCallOptimization = ScriptCallOptimizationLevel.FastButNoExceptions;
      break;
    }
    push_symbols();
    //
    update_symbols();
    BuildTarget buildTarget = BuildTarget.iOS;
    //string path = Path.GetFullPath(Application.dataPath + "/../project");
    string error = BuildPipeline.BuildPlayer(scenes, _buildPath,  buildTarget, opt);
    //
    pop_symbols();
    //
    if (string.IsNullOrEmpty(error)) {
      Debug.Log("build end");
      EditorApplication.Exit(0);
    } else {
      // build failed
      Debug.Log(error);
      EditorApplication.Exit(1);
    }
  }
  private static string[] GetAllScenes() {
    string[] allScene = new string[EditorBuildSettings.scenes.Length];
    int i = 0;
    foreach (EditorBuildSettingsScene scene in EditorBuildSettings.scenes) {
      allScene[i++] = scene.path;
    }
    return allScene;
  }
  private static List<string> get_argv(string name) {
    string[] args = System.Environment.GetCommandLineArgs();
    List<string> argv = new List<string>();
    for (int i = 0; i < args.Length; ++i) {
      string v = args[i];
      if (v == name && i < args.Length - 1) {
        argv.Add(args[i+1]);
      }
    }
    return argv;
  }
  private static void push_symbols() {
    BuildTargetGroup tg = EditorUserBuildSettings.selectedBuildTargetGroup;
    _bakDefines = PlayerSettings.GetScriptingDefineSymbolsForGroup(tg);
  }
  private static void pop_symbols() {
    BuildTargetGroup tg = EditorUserBuildSettings.selectedBuildTargetGroup;
    if (string.IsNullOrEmpty(_bakDefines)) {
      PlayerSettings.SetScriptingDefineSymbolsForGroup(tg, null);
    } else {
      PlayerSettings.SetScriptingDefineSymbolsForGroup(tg, _bakDefines);
    }
  }
  private static void update_symbols() {
    BuildTargetGroup tg = EditorUserBuildSettings.selectedBuildTargetGroup;
    List<string> symbols = get_argv("-symbol");
    string defines = PlayerSettings.GetScriptingDefineSymbolsForGroup(tg);
    Debug.Log(string.Format("OLD: {0}", defines));
    foreach (string sym in symbols) {
      defines += string.Format(";{0}", sym);
    }
    Debug.Log(string.Format("NEW: {0}", defines));
    PlayerSettings.SetScriptingDefineSymbolsForGroup(tg, defines);
  }
  private static Target get_target() {
    List<string> tgts = get_argv("-target");
    foreach (string t in tgts) {
      if (t == "DEV") return Target.Development;
      if (t == "REL") return Target.Release;
      if (t == "FNL") return Target.Final;
    }
    return Target.Unknown;
  }
}
