from ucimlrepo import fetch_ucirepo
import numpy as np
import json


def exists(dbConn, dataset : str) -> bool:
  """
  Aquesta funció mira si el dataset ja està inserit a la base de dades.

  :param dbConn: handle to an active (and open) connexion to Oracle DB.
  :param dataset: name of the dataset
  :return: True if  the dataset is already inserted in the DB
  """

  query = f"select *  from dataset where  name = '{dataset}'"



  return dbConn.cursor().execute(query).fetchone() is not None
  # return False


def insertVectorDataset(dbConn, nameDataset: str, *args, **kwargs) -> bool:
    """
    Inserts a UCI dataset (Vector format) into Oracle DB.
    Whole function = 1 transaction.
    """

    # Si ja existeix, res a fer
    if exists(dbConn, nameDataset):
        return True

    # Fetch dataset UCI
    dataset = fetch_ucirepo(name=nameDataset)

    # Dades principals
    X = dataset.data.features           # dataframe de caracteristiques
    y = dataset.data.targets            # dataframe amb la label
    meta = dataset.metadata             # info addicional
    
    # Caracteristiques del dataset
    feat_size = X.shape[1]
    num_classes = len(np.unique(y.iloc[:,0]))

    # Convertir metadata Python → JSON string
    info_json = json.dumps(meta)

    try:
        cursor = dbConn.cursor()

        # ---------------------------------------------------------
        # 1) INSERT A LA TAULA DATASET (prepare + bind variables)
        # ---------------------------------------------------------
        insert_dataset_sql = """
            INSERT INTO DATASET (ID, NAME, FEAT_SIZE, NUMCLASSES, INFO)
            VALUES (:1, :2, :3, :4, :5)
        """

        cursor.prepare(insert_dataset_sql)

        # ID = usar una seqüència? (si no existeix, tocarà crear-la)
        # Solució simple: agafem MAX(ID)+1
        cursor.execute("SELECT NVL(MAX(ID),0)+1 FROM DATASET")
        new_id = cursor.fetchone()[0]

        cursor.execute(None, [new_id,
                              nameDataset,
                              feat_size,
                              num_classes,
                              info_json])

        # ---------------------------------------------------------
        # 2) INSERT A LA TAULA SAMPLES
        # ---------------------------------------------------------
        insert_sample_sql = """
            INSERT INTO SAMPLES (ID_DATASET, ID, FEATURES, LABEL)
            VALUES (:1, :2, :3, :4)
        """

        cursor.prepare(insert_sample_sql)

        # Recorrer files del dataframe
        for i, row in X.iterrows():

            # Convertir vector → string JSON per Oracle VECTOR (CLOB)
            features_string = "[" + ",".join(map(str, row.to_list())) + "]"

            label_value = str(y.iloc[i,0])

            cursor.execute(None, [
                new_id,          # ID_DATASET
                i+1,             # ID mostra
                features_string, # VECTOR (CLOB/string)
                label_value
            ])

        # Tot correcte → commit
        dbConn.commit()
        return True

    except Exception as e:
        print("ERROR inserting dataset:", e)
        dbConn.rollback()
        return False

