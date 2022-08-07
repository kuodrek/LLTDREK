import numpy as np
import numpy.linalg as npla


# Function to calculate the induced velocity caused by a vortex panel in a point
def get_induced_velocity(collocation_point, vertice_point_1, vertice_point_2, v_inf, mac, h, same_panel_check): 
    ri1j = np.zeros(3)
    ri2j = np.zeros(3)
    velocity_ij = np.zeros(3)

    ri1j = collocation_point - vertice_point_1
    ri2j = collocation_point - vertice_point_2

    ri1j_abs = npla.norm(ri1j)
    ri2j_abs = npla.norm(ri2j)
    r1_cross_prod = np.cross(v_inf, ri1j)
    r2_cross_prod = np.cross(v_inf, ri2j)
    r1_dot_prod = np.dot(v_inf, ri1j)
    r2_dot_prod = np.dot(v_inf, ri2j)
    
    velocity_ij = mac / (4 * np.pi) * \
        ( r2_cross_prod / (ri2j_abs*(ri2j_abs-r2_dot_prod)) \
        - r1_cross_prod / (ri1j_abs*(ri1j_abs-r1_dot_prod)) )
    
    if not same_panel_check:
        r12_cross_prod = np.cross(ri1j, ri2j)
        r12_dot_prod = np.dot(ri1j, ri2j)
        velocity_ij +=  mac / (4 * np.pi) * \
            ( (ri1j_abs+ri2j_abs) * r12_cross_prod / (ri1j_abs*ri2j_abs*(ri1j_abs*ri2j_abs+r12_dot_prod)) )
    
    return velocity_ij
