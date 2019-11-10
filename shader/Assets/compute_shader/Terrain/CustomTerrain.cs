using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript : MonoBehaviour {

    public Material[] Materials;
    public ComputeShader ComputeShader;
    public Texture2D InitialState;
    public Material InitHeightMap;
    public Texture2D RainMap;

    public int Width = 256;
    public int Height = 256;

    public float BrushAmount = 0f;

    public InputModes InputMode = InputModes.AddWater;
    
    public enum InputModes
    {
        AddWater,
        RemoveWater,
        AddTerrain,
        RemoveTerrain,
    }

    public class SimulationSettings
    {
        public float TimeScale = 1f;
        public float PipeLength = 1f / 256;
        public Vector2 CellSize = new Vector2(1f / 256, 1f / 256);
        public float RainRate = 0.012f;

        public float Evaporation = 0.015f;  //蒸发
        public float PipeArea = 20;     // 管道

        public float Gravity = 9.81f;

        public float sedimentCapacity = 1f; // 积累能力

        public float SoilSuspensionRate = 0.5f; // 固体悬浮率

        public float SedimentDepositionRate = 5f; // 沉积率

        public float MaximalErosionDepth = 10f; // 最大沉积深度

    }
}
