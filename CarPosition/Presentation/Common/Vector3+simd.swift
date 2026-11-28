import simd

extension Vector3 {
    /// Las tres primeras componentes de una columna de una matriz 4×4 de ARKit.
    ///
    /// Vive en presentación porque el dominio no importa `simd`.
    init(_ column: simd_float4) {
        self.init(Double(column.x), Double(column.y), Double(column.z))
    }

    /// El vector en el formato que usa SceneKit.
    var simdVector: simd_float3 {
        simd_float3(Float(x), Float(y), Float(z))
    }
}
