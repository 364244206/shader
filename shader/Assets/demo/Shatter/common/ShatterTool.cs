using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Roma
{
    public class ShatterTool: MonoBehaviour
    {

        public Hull m_Hull;
        //private UvMapper uvMapper;

        void Start()
        {
            m_Hull = new Hull(GetComponent<MeshFilter>().mesh);
        }

        public void Split(Plane[] planes)
        {
            if (planes == null || planes.Length == 0 || m_Hull == null || m_Hull.IsEmpty)
            {
                return;
            }

            Plane[] localPlanes;
            CreateLocalPlanes(planes, out localPlanes);

            List<Hull> newHulls;
            CreateNewHulls(localPlanes, out newHulls);

            GameObject[] newGameObjects;
            CreateNewGameObjects(newHulls, out newGameObjects);



            Destroy(gameObject);
        }

        private void CreateLocalPlanes(Plane[] planes, out Plane[] localPlanes)
        {
            localPlanes = new Plane[planes.Length];
            for(int i = 0; i < planes.Length; i ++)
            {
                Plane plane = planes[i];
                // 世界空间中的点转到本地坐标
                Vector3 localPoint = transform.InverseTransformPoint(plane.normal * -plane.distance);
                Vector3 localNormal = transform.InverseTransformDirection(plane.normal);

                localNormal.Scale(transform.localScale);
                localNormal.Normalize();

                localPlanes[i] = new Plane(localNormal, localPoint);
            }
        }

        private void CreateNewHulls(Plane[] localPlanes, out List<Hull> newHulls)
        {
            newHulls = new List<Hull>();
            newHulls.Add(m_Hull);
            foreach(Plane item in localPlanes)
            {
                int hullNum = newHulls.Count;
                for(int i = 0; i < hullNum; i ++)
                {
                    Hull preHull = newHulls[0];
                    Hull a, b;
                    //preHull.Split(item.normal * -item.distance, item.normal, false, uvMapper, out a, out b);

                    //newHulls.Remove(preHull);

                    //if(!a.IsEmpty)
                    //{
                    //    newHulls.Add(a);
                    //}
                    //if(!b.IsEmpty)
                    //{
                    //    newHulls.Add(b);
                    //}
                }
                
            }
        }

        private void CreateNewGameObjects(List<Hull> newHulls, out GameObject[] newGameObjects)
        {
            Mesh[] newMeshes = new Mesh[newHulls.Count];
            float[] newVolumes = new float[newHulls.Count];

            float totalVolume = 0.0f;
            for(int i=0; i < newHulls.Count; i ++)
            {
                Mesh mesh = newHulls[i].GetMesh();
                Vector3 size = mesh.bounds.size;
                float volume = size.x * size.y * size.z;

                newMeshes[i] = mesh;
                newVolumes[i] = volume;

                totalVolume += volume;
            }

            newGameObjects = new GameObject[newHulls.Count];
            for(int i = 0; i < newHulls.Count; i ++)
            {
                Hull newHull = newHulls[i];
                Mesh newMesh = newMeshes[i];
                float volume = newVolumes[i];

                GameObject newGameObject = (GameObject)Instantiate(gameObject);
                ShatterTool newShatterTool = newGameObject.GetComponent<ShatterTool>();
                if (newShatterTool != null)
                {
                    newShatterTool.m_Hull = newHull;
                }

                MeshFilter newMeshFilter = newGameObject.GetComponent<MeshFilter>();
                if (newMeshFilter != null)
                {
                    newMeshFilter.mesh = newMesh;
                }
                MeshCollider newMeshCollider = newGameObject.GetComponent<MeshCollider>();
                if (newMeshCollider != null)
                {
                    newMeshCollider.sharedMesh = newMesh;
                }

                // Set rigidbody
                Rigidbody newRigidbody = newGameObject.GetComponent<Rigidbody>();
                if (newRigidbody != null)
                {
                    newRigidbody.mass = GetComponent<Rigidbody>().mass * (volume / totalVolume);

                    if (!newRigidbody.isKinematic)
                    {
                        newRigidbody.velocity = GetComponent<Rigidbody>().GetPointVelocity(newRigidbody.worldCenterOfMass);

                        newRigidbody.angularVelocity = GetComponent<Rigidbody>().angularVelocity;
                    }
                }

                newGameObjects[i] = newGameObject;
            }
        }
    }
}



