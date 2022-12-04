import numpy as np
from models.wing import Wing
from models.flight_condition import FlightCondition
from models.wingpool import WingPool
from models.simulation import Simulation
from utils import data


airfoils_data_dict, airfoils_dat_dict = data.load_folder('airfoils_test')

# Testing terms of the newton corrector equation and its symmetries

asa = Wing(
        spans=[3, 2],
        chords=[1, 1, 1],
        offsets=[0, 0, 0],
        twist_angles=[0, 0, 0],
        dihedral_angles=[0, 0],
        airfoils=['naca64210', 'naca64210', 'naca2412'],
        N_panels=12,
        distribution_type="cosine",
        sweep_check=False,
        surface_name='asa'
    )

asa.generate_mesh()

flight_condition = FlightCondition(
    V_inf=15,
    nu=1.5e-5,
    rho=1.225,
    aoa = [1],
    ground_effect_check=False
)

asa.setup_airfoil_data(flight_condition, airfoils_data_dict)

wingpool = WingPool(
    wing_list=[asa],
    flight_condition=flight_condition
)

simulation = Simulation(
    wing_pool=wingpool,
)

simulation.run_simulation()

# v_inf_array = flight_condition.v_inf_list[0]

# # testando métodos que atualizam dicionarios de velocidade total e distribuiçao de alfa
# total_velocity_dict = wingpool.calculate_total_velocity(v_inf_array)
# wingpool.calculate_aoa_eff(total_velocity_dict)

a=1