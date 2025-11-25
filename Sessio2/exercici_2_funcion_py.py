from ucimlrepo import fetch_ucirepo
import numpy as np
import json

def exists(dbConn, dataset: str) -> bool:
    query = "SELECT 1 FROM DATASET WHERE NAME = :name"
    cursor = dbConn.cursor()
    return cursor.execute(query, [dataset]).fetchone() is not None


def insertVectorDataset(dbConn, nameDataset: str, *args, **kwargs) -> bool:

    if exists(dbConn, nameDataset):
        print(f"{nameDataset}: ja existeix, no s'insereix.")
        return True

    dataset = fetch_ucirepo(name=nameDataset)

    X = dataset.data.features
    y = dataset.data.targets
    meta = dataset.metadata

    feat_size = X.shape[1]
    num_classes = len(np.unique(y.iloc[:, 0]))

    info_json = json.dumps(meta)

    try:
        cursor = dbConn.cursor()

        # Obtener nuevo ID del dataset
        cursor.execute("SELECT NVL(MAX(ID),0)+1 FROM DATASET")
        new_id = cursor.fetchone()[0]

        # Insert en tabla DATASET
        insert_dataset_sql = """
            INSERT INTO DATASET (ID, NAME, FEAT_SIZE, NUMCLASSES, INFO)
            VALUES (:1, :2, :3, :4, :5)
        """

        cursor.execute(insert_dataset_sql, [
            new_id,
            nameDataset,
            feat_size,
            num_classes,
            info_json
        ])

        # --------------------------------------------
        # Insert masivo optimizado para SAMPLES
        # --------------------------------------------
        insert_sample_sql = """
            INSERT INTO SAMPLES (ID_DATASET, ID, FEATURES, LABEL)
            VALUES (:1, :2, :3, :4)
        """

        rows_to_insert = []
        for i, row in X.iterrows():
            features_string = "[" + ",".join(map(str, row.to_list())) + "]"
            rows_to_insert.append([
                new_id,
                i+1,
                features_string,
                str(y.iloc[i, 0])
            ])

        cursor.executemany(insert_sample_sql, rows_to_insert)

        # Commit final
        cursor.connection.commit()
        print(f"{nameDataset}: inserit correctament (optimitzat executemany).")
        return True

    except Exception as e:
        print("ERROR inserting dataset:", e)
        cursor.connection.rollback()
        return False
