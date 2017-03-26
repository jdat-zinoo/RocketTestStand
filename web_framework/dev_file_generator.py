import os
import random
import uuid

sample_size = 10000
csv_first_line = 'sample, value\n'
csv_line = '%04d, %04d\n'


def create_file(sequence):
    filename = os.path.join(os.getcwd(), 'mock_filesystem', str(uuid.uuid4()) + '.csv')
    f = open(filename, 'wb')
    f.write(csv_first_line)
    for i in range(sample_size):
        f.write(csv_line % (i, sequence[i]))
    f.flush()
    f.close()


def create_sequence():
    s = []
    for i in range(sample_size):
        s.append(random.randint(0, 9999))
    s.sort()
    s.reverse()
    return s

if __name__ == '__main__':
    create_file(create_sequence())