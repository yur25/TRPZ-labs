import numpy

def get_matrix_product():
    a = numpy.random.rand(10, 10)
    b = numpy.random.rand(10, 10)
    return {"matrix_a": a.tolist(), "matrix_b": b.tolist(), "product": numpy.matmul(a, b).tolist()}

if __name__ == "__main__":
    print("Numpy test app running")
